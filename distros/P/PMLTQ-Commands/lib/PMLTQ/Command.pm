package PMLTQ::Command;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Command::VERSION = '2.0.1';
# ABSTRACT: Command base class

use PMLTQ::Base -base;

use utf8;

use DBI;
use File::Slurp;
use Pod::Usage 'pod2usage';

use JSON;
use LWP::UserAgent;
use HTTP::Cookies;
use URI::WithBase;
use URI::Encode qw(uri_encode);
use Encode;

has config => sub { die 'Command has no configuration'; };

has usage => sub {'Usage: '};

has term => sub {
  require Term::UI;
  require Term::ReadLine;
  Term::ReadLine->new('pmltq');
};

has term_encoding => sub {
  require Term::Encoding;
  Term::Encoding::get_encoding();
};

sub run {
  die 'Override by parent class';
}

sub extract_usage {
  my $self = shift;

  open my $handle, '>', \my $output;
  pod2usage( -exitval => 'NOEXIT', -input => (caller)[1], -output => $handle );
  $output =~ s/\n$//;

  return $output;
}

sub help {
  print shift->usage;
}

sub _db_connect {
  my ( $database, $host, $port, $user, $password ) = @_;
  my $dbh = DBI->connect( 'DBI:Pg:dbname=' . $database . ';host=' . $host . ';port=' . $port,
    $user, $password, { RaiseError => 1, PrintError => 1 } )
    or die "Unable to connect to database!\n$DBI::errstr\n";
  return $dbh;
}

sub db {
  my $self = shift;

  my $db = $self->config->{db};
  return _db_connect( $db->{name}, $db->{host}, $db->{port}, $db->{user}, $db->{password} );
}

sub sys_db {
  my $self = shift;

  my $config = $self->config;
  my $db     = $config->{db};
  my $sys_db = $config->{sys_db};

  unless ( ref $sys_db ) {
    $sys_db = { name => $sys_db };
  }

  $sys_db->{$_} = $db->{$_} for ( grep { !defined $sys_db->{$_} } qw/user password/ );

  return _db_connect( $sys_db->{name}, $db->{host}, $db->{port}, $sys_db->{user}, $sys_db->{password} );
}

sub run_sql_from_file {
  my ( $self, $file, $dir, $dbh ) = @_;

  my $sqlfile = File::Spec->catfile( $dir, $file );
  my $sql = read_file($sqlfile);

  print STDERR "RUNNING SQL FROM $sqlfile\n";
  if ( $file =~ m/.ctl/ and my $copy = () = $sql =~ m/(COPY .*? FROM *?["'].*?["'])/g ) {
    die "More COPY commands than one in file is not supported.\n\n$sql\n" if $copy > 1;
    $sql =~ s/(COPY .*? FROM) *?["'](.*?)["']/$1 STDIN/;
    my $dump_file = File::Spec->catfile( $dir, $2 );
    eval {
      $dbh->do($sql);
      open my $fh, '<', "$dump_file" or die "Can't open $dump_file: $!";
      while ( my $data = <$fh> ) {    # Do not load whole file, but process it line by line
        next unless $data;
        $data= Encode::decode("UTF-8", $data, Encode::FB_CROAK);
        $dbh->pg_putcopydata("$data");
      }
      $dbh->pg_putcopyend();
    };
    warn $@ if $@;
  }
  else {
    my @statements = split /\n\n/, $sql;
    for my $s (@statements) {
      eval { $dbh->do($s); };
      print STDERR "SQL FAILED:\t$s\n\t$@\n" if $@;
    }
  }
}

# Borrowed from https://metacpan.org/release/Dist-Zilla
sub prompt_str {
  my ( $self, $prompt, $arg ) = @_;

  $arg ||= {};
  my $default = $arg->{default};
  my $check   = $arg->{check};

  require Encode;
  my $term_encoding = $self->term_encoding;

  my $encode
    = $term_encoding
    ? sub { Encode::encode( $term_encoding, shift, Encode::FB_CROAK() ) }
    : sub {shift};
  my $decode
    = $term_encoding
    ? sub { Encode::decode( $term_encoding, shift, Encode::FB_CROAK() ) }
    : sub {shift};

  my $input_bytes = $self->term->get_reply(
    prompt => $encode->($prompt),
    allow  => $check || sub { defined $_[0] and length $_[0] },
    ( defined $default
      ? ( default => $encode->($default) )
      : ()
    ),
  );

  my $input = $decode->($input_bytes);
  chomp $input;

  return $input;
}

sub prompt_yn {
  my ( $self, $prompt, $arg ) = @_;
  $arg ||= {};
  my $default = $arg->{default};

  my $input = $self->term->ask_yn(
    prompt => $prompt,
    ( defined $default ? ( default => $default ) : () ),
  );

  return $input;
}

# WEB

sub ua {
  my $self = shift;
  $self->{ua} =  LWP::UserAgent->new() unless $self->{ua};
  return $self->{ua};
}

sub login {
  my ($self,$ua,$auth) = @_;
  my $url = URI::WithBase->new('/',$auth->{baseurl}||$self->config->{web_api}->{url});
  $url->path_segments('api','auth');

  my $res = $self->request($ua,'POST',$url->abs->as_string,{auth => {password => $auth->{password} || $self->config->{web_api}->{password}, username => $auth->{username} || $self->config->{web_api}->{user}}});
  my $cookie_jar = HTTP::Cookies->new();
  $cookie_jar->extract_cookies($res);
  $ua->cookie_jar($cookie_jar);
}

sub request {
  my ($self,$ua,$method, $url,$data) = @_;
  my $JSON = JSON->new->utf8;
  my $req = HTTP::Request->new( $method => $url );
  $req->content_type('application/json;charset=UTF-8');
  if($data) {
    $data = $JSON->encode($data);
    $data =~ s/"false"/false/g;
    $data =~ s/"true"/true/g;
    $req->content($data);
  }
  my $res = eval { $ua->request( $req ); };
  confess($@) if $@;
  unless ( $res->is_success ) {
    if($res->code() == 502) {
      die "Error while executing query.\n";
    } else {
      die "Error reported by PML-TQ server:\n\n" . $res->content . "\n";
    }
    return;
  }
  if(wantarray) {
    return ($res,$res->decoded_content) unless $res->content_type eq 'application/json';
    my $json = $res->decoded_content;
    return ($res,$json ? $JSON->decode($json) : undef);
  }
  return $res;
}

sub get_all_treebanks {
  my ($self,$ua, $apiurl) = @_;
  my $data;
  my $url = URI::WithBase->new('/',$apiurl || $self->config->{web_api}->{url});
  $url->path_segments('api','admin', 'treebanks');
  (undef,$data) = $self->request($ua,'GET',$url->abs->as_string);
  return $data // [];
}

sub get_treebank {
  my ($self,$ua) = @_;
  my ($treebank) = grep {$_->{name} eq $self->config->{treebank_id}} @{ $self->get_all_treebanks($ua)};
  return $treebank;
}

sub request_treebank {
  my ($self,$treebank,$ua,$method,$data) = @_;
  my $url = URI::WithBase->new('/',$self->config->{web_api}->{url});
  $url->path_segments('api','admin', 'treebanks',$treebank->{id});
  (undef,$data) = $self->request($ua,$method,$url->abs->as_string,$data);
}

sub create_treebank_param {
  my ($self) = @_;
  my (@langs,@tags,@server);
  my @searches = (
    {
      results => \@langs,
      configpath => ['languages'],
      api => 'languages',
      compare => 'code',
      error => "Unknown language code '\%s'\n",
      min => 0
    },
    {
      results => \@tags,
      configpath => ['tags'],
      api => 'tags',
      compare => 'name',
      error => "Unknown tag '\%s'\n",
      min => 0
    },
    {
      results => \@server,
      configpath => ['web_api','dbserver'],
      api => 'servers',
      compare => 'name',
      no_url_filter => 1,
      error => "Unknown server name '\%s'\n",
      min => 1
    },
  );
  for my $search (@searches) {
    my $config_values = $self->config;
    for my $path (@{$search->{configpath}}) {
      $config_values = $config_values->{$path};
    }
    $config_values = $config_values ? (ref $config_values ? $config_values : [$config_values] )  : [];
    for my $text (@{$config_values}) {
      my $res = $self->_search_param($text,$search);
      if($res) {
        push @{$search->{results}}, $res->{id};
      } else {
        die "ERROR: " . sprintf($search->{error},$text);
      }
    }
    die "ERROR: " . $search->{min} . " " . join("-",@{$search->{configpath}}) . " is required\n" unless @{$search->{results}} >= $search->{min} ;
  }

  return {
    title => $self->config->{title},
    name => $self->config->{treebank_id},
    homepage => $self->config->{homepage},
    description => $self->config->{description},
    manuals => $self->config->{manuals},
    dataSources => [map { {layer => $_->{name},path => $_->{path} } }@{$self->config->{layers}}],
    tags => \@tags,
    languages => \@langs,
    serverId => $server[0],
    database => $self->config->{db}->{name},
    isFree => $self->config->{isFree},
    isAllLogged => $self->config->{isAllLogged},
    isPublic => $self->config->{isPublic},
    isFeatured => $self->config->{isFeatured},
  }
}

sub _search_param {
  my $self = shift;
  my $text = shift;
  my $opts = shift;
  my $url = URI::WithBase->new('/',$self->config->{web_api}->{url});
  $url->path_segments('api', 'admin', $opts->{api});
  my $data;
  (undef,$data) = $self->request($self->{ua}, 'GET', $url->abs->as_string.($opts->{no_url_filter} ? '' : "?filter=".URI::Encode::uri_encode("{\"q\":\"$text\"}")), {});
  my ($res) = grep {$_->{$opts->{compare}} eq $text } @$data;
  return $res;
}


sub evaluate_query {
  my ($self,$tb_id,$query) = @_;
  my $url = URI::WithBase->new('/',$self->config->{web_api}->{url});
  $url->path_segments('api', 'treebanks', $tb_id, 'query');
  my $data;
  (undef,$data) = $self->request($self->{ua}, 'POST', $url->abs->as_string, {filter => "true", limit => 100, query => $query, timeout => 30});
  my $result = '';
  unless($data) {
    print STDERR "Error while executing query: $query\n";
  } else {
    my $results = $data->{results};
    if(@$results) {
      if($data->{nodes}) { # tree result
        $url = URI::WithBase->new('/',$self->config->{web_api}->{url});
        $url->path_segments('api', 'treebanks', $tb_id, 'svg');
        (undef,$result) = $self->request($self->{ua}, 'POST', $url->abs->as_string, {nodes => $results->[0], tree => 0});
      } else { # filter result
        $result = join("\n",map {join("\t",@$_)} @$results) . "\n";
      }
    } else {
      print STDERR "Empty result for: $query\n";
    }
  }
  return $result;
}

sub user2admin_format { # converts getted treebank json to treebank configuration format
  my ($self, $treebank) = @_;
  return {
    id => $treebank->{name},
    tags => [map  {$_->{name}} @{$treebank->{tags}}],
    language => $treebank->{languages}->[0]->{code},
    map {$_ => $treebank->{$_}} qw/title isFree isAllLogged isFeatured isPublic homepage description documentation dataSources manuals/
  }
}


sub get_nodetypes {
  my ($self, $treebank) = @_;
  my $url = URI::WithBase->new('/',$self->config->{web_api}->{url});
  $url->path_segments('api', 'treebanks', $treebank->{name}, 'node-types');
  my $data;
  (undef,$data) = $self->request($self->{ua}, 'GET', $url->abs->as_string);
  return $data->{types}
}

sub get_test_queries {
  my ($self, $treebank) = @_;
  # get node types
  my ($type) = @{$self->get_nodetypes($treebank)};
  return [{filename=>"$type.svg", query => "$type [];"}, {filename=>"${type}_count.txt", query => "$type []; >> count()"}]
}

1;
