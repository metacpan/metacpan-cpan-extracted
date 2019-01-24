package PMLTQ::Command::query;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Command::query::VERSION = '2.0.2';
# ABSTRACT: WIP: Executes query on treebank

use PMLTQ::Base 'PMLTQ::Command';
use PMLTQ;
use Cwd;
use File::Spec;

use Treex::PML;
use Treex::PML::Instance;
use Treex::PML::Schema;
use Getopt::Long qw(GetOptionsFromArray);
use PMLTQ::Common ':tredmacro';
use HTTP::Request::Common;
use LWP::UserAgent;
use File::Temp;
use Encode;
use Pod::Usage 'pod2usage';
use JSON;

my $extension_dir;
my %opts;

has usage => sub { shift->extract_usage };

sub run {
  my $self = shift;
  my @args = @_;
  GetOptionsFromArray(\@args, \%opts,
  'debug|D',
  'server|s=s',
  'command|c=s',

  'ntred|N',
  'jtred|J',
  'btred|B',
  'sql|S',
  'shared-dir|d=s',
  'keep-tmp-files',
  'filelist|l=s',

  'username=s',
  'password=s',
  'auth-id=s',

  'pmltq-extension-dir|X=s',

  'stdin',
  'query|Q=s',
  'query-id|i=s',
  'query-file|f=s',
  'query-pml-file|p=s',
  'filters|F=s',
  'no-filters',

  'old-api',
  'output-json',

  'netgraph-query|G=s',

  'print-servers|P',
  'config-file|c=s',

  'node-types|n',
  'relations|r',

  'limit|L=i',
  'timeout|t=i',
  'history|H',

  'quiet|q',
  'help|h=s@',
  'usage|u',
  'version|V',
  'man' ) || die "invalid options";
  Treex::PML::AddResourcePath(
       PMLTQ->resources_dir,
       File::Spec->catfile(${FindBin::RealBin},'config'),
       $ENV{HOME}.'/.tred.d'
      );
  Treex::PML::AddBackends(qw(Storable PMLBackend PMLTransformBackend));

  if ($opts{stdin}) {
    local $/;
    $opts{query} = <STDIN>;
  }

  $opts{$1}=1 if defined($opts{server}) and $opts{server}=~s{^[nbj]tred://}{};
  $extension_dir =
    $opts{'pmltq-extension-dir'} ||
    File::Spec->catfile($ENV{HOME},'.tred.d','extensions', 'pmltq');
  Treex::PML::AddResourcePath(File::Spec->catfile($extension_dir,'resources'));
  if ($opts{ntred}) {
    ntred_search();
  } elsif ($opts{jtred}) {
    jtred_search();
  } elsif ($opts{btred}) {
    btred_search(@args);
  } else {
    $self->pmltq_http_search();
  }
}

my %auth;
sub pmltq_http_search {
  my $self = shift;
  my @args = @_;
  my $query;
  if ($opts{query} and !@args) {
    $query = $opts{query};
  } elsif (!$query and @args) {
    $query=join ' ',@args;
  } elsif ($opts{'query-pml-file'}) {
    my $query_file = Treex::PML::Factory->createDocumentFromFile($opts{'query-pml-file'});
    die "Failed to open PML query file $opts{'query-pml-file'}: $Treex::PML::FSError\n" if $Treex::PML::FSError or !$query_file or !$query_file->trees;
    $query = first {
      !$opts{'query-id'} or $_->{id} and $_->{id} eq $opts{'query-id'}
    } $query_file->trees;
    die "Didn't find query $opts{'query-id'} in query file $opts{'query-pml-file'}!" unless $query;
    $query = encode('UTF-8',PMLTQ::Common::as_text($query));
  } elsif ($opts{'query-file'}) {
    local $/;
    open my $fh, $opts{'query-file'}
      or die "Cannot open query file '$opts{'query-file'}': $!";
    $query = <$fh>;
    if ($opts{'query-id'}) {
      $query=~s/#\s*==\s*query:\s*\Q$opts{'query-id'}\E\s* ==(.*?)(?:#\s*==\s*query:\s*\w+\s*==.*|$)/$1/s;
    }
  } elsif (!$opts{'node-types'} and !$opts{'relations'} and !$opts{'print-servers'}) {
    pod2usage(-msg => 'pmltq');
    exit 1;
  }
  if (!$opts{'query-pml-file'} and $opts{'netgraph-query'}) {
    require PMLTQ::NG2PMLTQ;
    $query = PMLTQ::NG2PMLTQ::ng2pmltq($query,{type=>$opts{'netgraph-query'}});
  }

  if (!$opts{'node-types'} and !$opts{'relations'} and !$opts{'print-servers'}) {
    die "Query is empty!" unless $query;

    my $filters = $opts{'filters'};
    if ($filters and $filters=~/\S/) {
      $filters='>> '.$filters unless $filters =~ /^\s*>>/;
      $query .= $filters;
    }
  }

  $opts{'config-file'} ||= Treex::PML::FindInResources('treebase.conf');
  if ($opts{debug}) {
    print STDERR "Reading configuration from $opts{'config-file'}\n";
  }
  my $configs = (-f $opts{'config-file'}) ?
      Treex::PML::Factory->createPMLInstance({ filename=>$opts{'config-file'} })->get_root->{configurations}
  : undef;

  my $id = $opts{'server'};
  $id ||= 'default' unless $opts{'print-servers'};
  my ($conf,$type) = $id ? get_server_conf($configs,$id, $opts{'old-api'}) : ();
  %auth = (
    username => $opts{username},
    password => $opts{password},
   );
  if ($opts{'auth-id'}) {
    my ($auth) = get_server_conf($configs,$opts{'auth-id'}, $opts{'old-api'});
    if ($auth) {
      $auth{$_} ||= $auth->{$_} for qw(username password);
    } else {
      die "Didn't find auth-id configuration: $opts{'auth-id'}\n";
    }
  }
  if ($conf) {
    $auth{$_} ||= $conf->{$_} for qw(username password baseurl);
  }


  if ($opts{'print-servers'}) {
    if ($opts{'server'}) {
      unless ($type eq 'http') {
  die "Cannot query available services on a $type server";
      }
      my $result='';
      $self->http_search($conf->{url},$query,{ other=>1,
          callback => sub { $result.=$_[0] },
          debug=>$opts{debug},
          %auth,
          'baseurl' => $conf->{baseurl}
               });
      my @services = split /\n/,$result;
      for my $srv (@services) {
  my %srv = map { split(':',$_,2) } split /\t/, $srv;
  print $srv{id},"\t",$srv{service},"\t",$srv{title},"\n";
      }
      exit;
    }
    my @types = qw(dbi http);
    my %columns = (
      dbi => [qw(driver host port database username sources)],
      http => [qw(url username cached_description/title)],
     );
    my %configs = (
      map { my $type = $_; ($_ =>[map $_->value, grep { $_->name eq $type } SeqV($configs)]) }
  @types
       );
    for my $type (@types) {
      my $confs = $configs{$type};
      if (@$confs) {
  print uc($type)." configurations:\n";
  print (("-"x60)."\n");
  no warnings;
  for my $c (@$confs) {
    print $c->{id}.": ".(join(", ", map "$_->[0]=$_->[1]",
            grep length($_->[1]),
            map [m{/(.*)} ? $1 : $_,Treex::PML::Instance::get_data($c,$_)], @{$columns{$type}})."\n");
  }
      }
      print "\n";
    }
    exit;
  }



  print STDERR $query,"\n" if $opts{debug};



  if ($type eq 'http') {
    #if($opts{'old-api'}){
    $self->http_search($conf->{url},$query,{ 'node-types'=>$opts{'node-types'},
              'relations'=>$opts{'relations'},
              debug=>$opts{debug},
              %auth,
              'old-api'=>$opts{'old-api'},
              'output-json'=>$opts{'output-json'},
              'baseurl' => $conf->{baseurl}
             });
    #} else { ## NEW API
    #  print STDERR "TODO NEW API\n";
    #}
  } else {
    require PMLTQ::SQLEvaluator;
    my $evaluator = PMLTQ::SQLEvaluator->new(undef,{connect => $conf, debug=>$opts{debug},
               %auth
              });
    $evaluator->connect();
    if ($opts{'node-types'}) {
      print join "\n", @{$evaluator->get_node_types};
    } elsif ($opts{'relations'}) {
      print join "\n", @{$evaluator->get_specific_relations};
    } else {
      search($evaluator,$query);
    }
    $evaluator->{dbi}->disconnect() if $evaluator->{dbi};
  }
}

sub get_server_conf {
  my ($configs,$id, $oldapi)=@_;
  my ($conf,$type);
  if ($id =~ /^https?:/) {
    $type = 'http';
    $conf = {url => $id};
    unless($oldapi) {
      $conf->{baseurl} = $id;
      $conf->{baseurl} =~ s@api/treebanks.*?$@@;
    }
  } else {
    my $conf_el = first { $_->value->{id} eq $id }  SeqV($configs);
    die "Didn't find server configuration named '$id'!\nUse $0 --print-servers and then $0 --server <config-id|URL>\n"
      unless $conf_el;
    $conf = $conf_el->value;
    unless($oldapi) {
      $conf->{baseurl} = $conf->{url};
      $conf->{url} = URI::WithBase->new('/',$conf->{url});
      $conf->{url}->path_segments('api', 'treebanks', $conf->{treebank});
      $conf->{url} = $conf->{url}->abs->as_string;
    }
    $type = $conf_el->name;
  }
  return ($conf,$type);
}

sub http_search {
  my ($self,$url,$query,$opts)=@_;
  $opts||={};
  my $tmp = File::Temp->new( TEMPLATE => 'pmltq_XXXXX',
           TMPDIR => 1,
           UNLINK => 1,
           SUFFIX => '.txt' );
  my $ua;
  if($opts->{'old-api'}) {
    $ua = LWP::UserAgent->new;
    $ua->credentials(URI->new($url)->host_port,'PMLTQ',
         $auth{username}, $auth{password})
      if $opts->{username};
  } else {
    $ua = $self->ua;
    $ua->agent("PMLTQ/1.0 ");
    $self->login($ua,\%auth) if $opts->{username};
  }
  $url.='/' unless $url=~m{^https?://.+/$};
  my $METHOD = \&POST;
  if ($opts->{'node-types'}) {
    $url = $opts->{'old-api'} ? qq{${url}nodetypes} : qq{${url}node-types};
    $METHOD = \&GET unless $opts->{'old-api'};
    $query = '';
  } elsif ($opts->{'relations'}) {
    $url = qq{${url}relations};
    $METHOD = \&GET unless $opts->{'old-api'};
    $query = '';
  } elsif ($opts->{'other'}) {
    $url = qq{${url}other};
     die "Unknown option --other in new api\n" unless $opts->{'old-api'};
    $query = '';
  } else {
    $url = qq{${url}query};
  }
  $ua->timeout($opts{timeout}+2) if $opts{timeout};
  my $q = $query; Encode::_utf8_off($q);
  binmode STDOUT;
  my $sub = $opts->{callback} || sub { print $opts{'output-json'} ? ($_[0]) : (map {join("\t",@$_)."\n"} @{JSON::from_json($_[0])->{results}}) };
  my $res = $ua->request($METHOD->($url, 
    $opts->{'old-api'} ?
      ([
        query => $q,
        format => 'text',
        limit => $opts{limit},
        row_limit => $opts{limit},
        timeout => $opts{timeout},
       ])
       :
       (
        Content_Type => 'application/json;charset=UTF-8',
        User_Agent => 'PML-TQ CLI',
        Content => JSON->new->utf8->encode({
          query => $q,
          limit => $opts{limit},
          # row_limit => $opts{limit}, #TODO: currently not working
          timeout => $opts{timeout},
          nohistory => !!$opts{history}
        })
       )
     ),$sub ,1024*8 );
  unless ($res->is_success) {
    die $res->status_line."\n".$res->content."\n";
  }
}



sub search {
  my ($evaluator,$query)=@_;
  my $results;
  eval {
    $evaluator->prepare_query($query); # count=>1
    $results = $evaluator->run({
      node_limit => $opts{limit},
      row_limit => $opts{limit},
      timeout => $opts{timeout},
      timeout_callback => sub {
  print STDERR "Evaluation of query timed out\n";
  exit 2;
      },
    });
  };
  warn $@ if $@;
  if ($results) {
    for my $r (@$results) {
      print join("\t",@$r)."\n";
    }
    print STDERR $#$results+1," result(s)\n" unless $opts{quiet};
  }
}

sub quote_cmdline {
  my $quoted;
  join ' ', map {
    my $arg = $_;
    $arg =~ s{'}{'\\''}g;
    qq{'$arg'}
  } @_;
}

sub ntred_search {
  my @args = @_;
  my ($host,$port)= $opts{server} ? split(/:/,$opts{server}) : ();
  my $command = $opts{command} || 'ntred';

  my $shared_dir=File::Spec->rel2abs($opts{'shared-dir'} || '.');
  my $filter_file="$shared_dir/pmltq_ntred_filter.$$.pl";

  my @script_flags=('--filter-code-out', $filter_file);
  foreach (qw(query query-id query-file query-pml-file filters netgraph-query)) {
    push @script_flags, '--'.$_, (/file/ ? File::Spec->rel2abs($opts{$_}) : $opts{$_})
      if defined($opts{$_}) and length($opts{$_});
  }

  $command .= ' '.quote_cmdline(
    ((defined($host) and length($host)) ? ('--hub',$host) : ()),
    ((defined($port) and length($port)) ? ('--port',$port) : ()),
    '-q',
    '-I', File::Spec->catfile($extension_dir,qw(contrib pmltq pmltq.ntred)),
    ($opts{filelist} ? ('-l', File::Spec->rel2abs($opts{filelist})) : (@args ? ('-L', '--', @args) : ())),
    '--', @script_flags
  );
  open(my $pipe, $command.' | ') || die "Failed to start ntred client: $!";
  apply_filter($pipe, $filter_file);
  close($pipe);
  unlink $filter_file if -f $filter_file and !$opts{'keep-tmp-files'};
}

sub jtred_search {
  my @args = @_;
  my $command = $opts{command} || 'jtred';

  my $jobname="pmltq_jtred_$$";
  if ($opts{server}) {
    $jobname.="-".$ENV{HOSTNAME};
  }

  my $shared_dir=File::Spec->rel2abs($opts{'shared-dir'} || '.');
  my $filter_file="$shared_dir/$jobname.pl";
  my $filelist;
  if ($opts{filelist}) {
    my ($vol,$dir) = File::Spec->splitpath($opts{filelist});
    my $base = File::Spec->catpath($vol,$dir);
    open my $fh, '<', $opts{filelist} or die "Cannot open filelist $opts{filelist}: $!";
    $filelist = "$shared_dir/$jobname.fl";
    open my $out_fh, '>', $filelist or die "Cannot create temporary filelist $filelist: $!";
    print STDERR "Resolving filelist files to $base...\n" unless $opts{quiet};
    while(<$fh>) {
      chomp;
      print $out_fh File::Spec->rel2abs($_,$base),"\n";
    }
    print STDERR "done.\n" unless $opts{quiet};
    close $fh;
    close $out_fh;
  }
  my @script_flags=('--filter-code-out', $filter_file);
  foreach (qw(query query-id query-file query-pml-file filters netgraph-query)) {
    push @script_flags, '--'.$_, (/file/ ? File::Spec->rel2abs($opts{$_}) : $opts{$_})
      if defined($opts{$_}) and length($opts{$_});
  }
  my @command = (
    $command,
    ($opts{'shared-dir'} ? ('-jw', $shared_dir) : ()),
    '-jn', $jobname,
    ($opts{quiet} ? '-jq' : ()),
    ($filelist ? ('-l', $filelist) : @args),
    '-jb',
    '-q',
    '-I', File::Spec->catfile($extension_dir,qw(contrib pmltq pmltq.ntred)),
    '-o',  @script_flags, '--'
  );
  my $pipe;
  if ($opts{server}) {
    my $cwd = quote_cmdline(getcwd());
    open($pipe, '-|', 'ssh', $opts{server}, <<"SCRIPT".quote_cmdline(@command))
if [ -f ~/.bash_profile ]; then
   . ~/.bash_profile 2>/dev/null 1>&2
elif [ -f ~/.profile ]; then
   . ~/.profile 2>/dev/null 1>&2
fi
cd $cwd;
SCRIPT
      || die "Failed to start jtred on host $opts{server} over ssh: $!"
  } else {
    open($pipe, '-|',@command)
      || die "Failed to start jtred: $!";
  }
  apply_filter($pipe, $filter_file);
  close($pipe);
  unlink $filter_file if -f $filter_file and !$opts{'keep-tmp-files'};
  unlink $filelist if $filelist and !$opts{'keep-tmp-files'};
}

sub btred_search {
  my @args = @_;
  my $command = $opts{command} || 'btred';

  my $jobname="pmltq_btred_$$";
  if ($opts{server}) {
    $jobname.="-".$ENV{HOSTNAME};
  }

  my $shared_dir=File::Spec->rel2abs($opts{'shared-dir'} || '.');
  my $filter_file="$shared_dir/$jobname.pl";

  my @script_flags=('--filter-code-out', $filter_file);
  foreach (qw(query query-id query-file query-pml-file filters netgraph-query)) {
    push @script_flags, '--'.$_, (/file/ ? File::Spec->rel2abs($opts{$_}) : $opts{$_})
      if defined($opts{$_}) and length($opts{$_});
  }
  for (qw(node-types relations)) {
    if ($opts{$_}) {
      push @script_flags, '--info', $_;
      last;
    }
  }

  $command .= ' '.quote_cmdline(
    ($opts{quiet} ? '-Q' : '-q'),
    '-I', File::Spec->catfile($extension_dir,qw(contrib pmltq pmltq.ntred)),
    '-o', '--apply-filters', @script_flags, '--',
    ($opts{filelist} ? ('-l', $opts{filelist}) : @args),
  );
  if ($opts{server}) {
    my $cwd = quote_cmdline(getcwd());
    system('ssh', $opts{server}, <<"SCRIPT");
if [ -f ~/.bash_profile ]; then
   . ~/.bash_profile
elif [ -f ~/.profile ]; then
   . ~/.profile;
fi
cd $cwd
$command
SCRIPT
  } else {
    print STDERR "$command\n";
    system($command);
  }
  unlink $filter_file if -f $filter_file and !$opts{'keep-tmp-files'};
}


sub round {
  my ($value, $precision) = @_;
  my $rounding = ($value >= 0 ? 0.5 : -0.5);
  my $decimalscale = 10**int($precision || 0);
  my $scaledvalue = int($value * $decimalscale + $rounding);
  return $scaledvalue / $decimalscale;
}

sub trunc {
  my ($self, $num, $digits) = @_;
  $digits = int $digits;
  my $decimalscale = 10**abs($digits);
  if ($digits >= 0) {
    return int($num * $decimalscale) / $decimalscale;
  } else {
    return int($num / $decimalscale) * $decimalscale;
  }
}

sub apply_filter {
  my ($input, $filter_file)=@_;
  my $filters;
  my $filter;
  my $first = 1;
  use POSIX qw(ceil floor);

  if ($opts{'no-filters'}) {
    print while (<$input>);
    return;
  }

  my $output_filter = {
    init => sub { },
    process_row => sub {
      my ($self,$row)=@_;
      print(join("\t",@$row)."\n");
    },
    finish => sub { }
   };

  while (<$input>) {
    chomp;
    unless ($filter) {
      if (-f $filter_file and -s $filter_file) {
  open my $fh, "<", $filter_file or
    die "Cannot open $filter_file: $!";
  my $filter_code;
  {
    local $/;
    $filter_code = <$fh>;
  }
  eval "use utf8;\n".$filter_code;
  if ($@) {
    print STDERR $filter_code;
    print STDERR "\n";
    die "Running filter $filter_file failed!";
  }
  my @filters = map {
    my @local_filters = map eval, @{$_->{local_filters_code}};
    my $sub = eval($_->{code});
    die $@ if $@;
    $sub
  } @$filters;

  # connect filters
  my $prev;
  for my $filter (@filters) {
    $prev->{output}=$filter if $prev;
    $prev = $filter;
  }
  if ($prev) {
    $prev->{output} = $output_filter;
  }
  $filter = $filters[0] || die "First filter is empty!";
  $filter->{init}->($filter);
      } else {
  $filter = $output_filter;
      }
    }
    $filter->{process_row}->($filter,[split /\t/,$_]);
  }
  $filter->{finish}->($filter) if $filter;
}

=head1 SYNOPSIS

  pmltq query [--server <URL_or_server_ID> ] [ <options> ] [ --stdin | --query-file <filename> | --query <query> | <query> ]
  pmltq query --btred [ <options> ] [ --stdin | --query-file <filename> | --query <query> ] [ -l <filelist> |  <file(s)> ]
  pmltq query --ntred [ <options> ] [ --stdin | --query-file <filename> | --query <query> ] [ -l <filelist> |  <file(s)> ]
  pmltq query --jtred [ <options> ] [ --stdin | --query-file <filename> | --query <query> ] [ -l <filelist> |  <file(s)> ]

or

  pmltq query [options] [ --print-servers|-P | --node-types | --relations ]


=head1 DESCRIPTION

Run the query.

=head1 OPTIONS

=over 5

=item B<--sql|-S>

Use SQL-based query engine (default).

=item B<--btred|-B>

Query given files or filelist using btred.

=item B<--ntred|-N>

Query given files or filelist using ntred (ntred servers
must be already up and running).

=item B<--jtred|-J>

Run query query over given files/filelist using jtred (multiple btred
instances distributed over an SGE cluster).

=item B<--server|-s> URL_or_ID

If used with SQL-based engine, this option can be used to specify a
URL (http://hostname/APIpath/treebanks/treebankID) to a pmltq http server, or an ID of a
pre-configured SQL or HTTP server (use B<--print-servers> to get a
list).

If used with btred or jtred, it can be used to specify a server to run
btred/jtred on using SSH.

If used with ntred, it can be used to specify a hostname and port
(hostname:port) for the ntred hub.

=item B<--stdin>

Read query from the standard input.

=item B<--query|-Q> string

Specify PML-TQ query on the command-line.

=item B<--query-file> filename

Read PML-TQ query from a given (utf-8 encoded text) file

=item B<--query-pml-file> filename

Read PML-TQ query from a given PML file

=item B<--query-id> ID

Use query with a given ID. If the input is a text file, it can contain more than one
query. In that case, each query must start with a line of the following form:

  # == query: ID ==

where ID is a unique identifier of the query. This option can be used
to select a single query from the input.

If the input is a PML file, then the ID is just the id of the query tree.

=item B<--filelist|-l> filename

This flag can be used with B<--btred>, B<--ntred>, or B<--jtred> to
spedify a file containing a list of files to search, each on a
separate line.

Note that for B<--ntred>, the files must be already loaded on the
B<ntred> servers and this flag simply allows you to specify a subcorpus.

=item B<--auth-id> URL_or_ID

Use username/password stored in the configuration for a given service
(spcified by URL or config-file ID) on the serice specified using --server.

=item B<--username> username

Username for a HTTP or SQL PML-TQ service.

=item B<--password> password

Password for a HTTP or SQL PML-TQ service.

=item B<--limit|-L> number

Only applicable to SQL-based engine.
Specify maximum number of results (i.e. rows printed by pmltq).

=item B<--history|-H>

Sets whether should be query logged to users query history on server.

=item B<--timeout|-t> seconds

Only applicable to SQL-based engine.
Specify a timeout for the query. If the query evaluation takes longer
than a given number of B<seconds>, pmltq terminates the connection
with the server and returns with a message "Evaluation of query timed
out" and exit code 2.

=item B<--config-file|-c> filename

Specify a configuration file. The configuration file is a XML file (in
fact, a PML instance conforming to the treebase_conf_schema.xml) that
lists available SQL engine configurations. If this option is not
provided, B<pmltq> attempts to find a file named treebase.conf in the
resource paths (namely in ~/.tred.d).

=item B<--node-types>

List available node types and exit.

=item B<--netgraph-query|-N> type_name

Assume the query is in NetGraph syntax and translate it to PMLTQ,
using a given node type as the default type.

=item B<--debug|-D>

Print some extended information (e.g. evaluation benchmarks).

=back

=cut

1;
