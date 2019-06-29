package PMLTQ::Suggest::Server;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Suggest::Server::VERSION = '1.0.4';
use base qw(HTTP::Server::Simple::CGI);
use URI;
use URI::file;

use PMLTQ::Suggest::Utils;
use PMLTQ::Suggest;

our $permitted_paths_re = '^(?:)/';
our %methods = map {$_ => 1} qw/GET/;

sub run {
    my $self = shift;
    if ($self->prefork) {
        $self->SUPER::run(@_, host => $self->host, ipv => 4, max_servers => $self->prefork);
    } else {
        $self->SUPER::run(@_);
    }
}

sub handle_request {
  my ($self, $cgi) = @_;
  eval {
      my $path = $cgi->path_info();
      my $method = $cgi->request_method();
      if ($path eq '/' and exists($methods{$method})) {
          servePMLTQ($self,$cgi);
      } else {
          notFound($cgi);
      }
  };

  serverError($cgi, $@) if ($@);
}

# Maximum number of servers to prefork
sub prefork {
    my $self = shift;
    $self->{prefork_child} = $_[0] if scalar @_ > 0;
    return $self->{prefork_child};
}

sub net_server { return $_[0]->prefork ? 'Net::Server::PreForkSimple' : undef; }

sub notFound {
  my ($cgi)=@_;
  print "HTTP/1.0 404 Not found\r\n";
  print $cgi->header,
    $cgi->start_html('Not found'),
    $cgi->h1('Not found'),
    $cgi->end_html;
}

sub serverError {
  my ($cgi, $error)=(@_,'');
  $error =~ tr/\n/ /;
  $error =~ s/ at .*$//;
  $error =~ s/\.\.\.propagated.*$//;
  print STDERR '['.localtime()."] $error\n";
  $error =~ s/'\/[^']*\/([^\/']*)'/'$1'/;

  print "HTTP/1.0 500 Internal server error\r\n";
  print $cgi->header,
    $cgi->start_html('Internal server error'),
    $cgi->h1('Error occurred while processing request!'),
    "\r\n",
    $cgi->p($error),
    $cgi->end_html;
}

sub servePMLTQ {
  my ($self,$cgi) = @_;             # Net::HTTPServer::Request object
  my @names = split(/,/,$cgi->param('r')||'');
  my $paths = $cgi->param('p');
  my @paths = $paths ? split(/\|/, $paths) : ();
  unless (@paths) {
    print STDERR '['.localtime()."] No path!\n";
    return notFound($cgi);
  }
  my @positions;
  foreach my $p (@paths) {
    my ($path, $goto)=PMLTQ::Suggest::Utils::parse_file_suffix($p);
    $path = URI->new($path)->canonical->as_string;
    if ($path=~m{/\.\./} or $path !~ $permitted_paths_re) {
      print STDERR '['.localtime()."] Path $path not permitted\n";
      return notFound($cgi);
    } elsif (!$goto) {
      print STDERR '['.localtime()."] Path $p does not contain an address\n";
      return notFound($cgi);
    }
    push @positions, [$path,$goto];
  }
  my $pmltq;
  eval {
    $pmltq = PMLTQ::Suggest::make_pmltq(
      \@positions,
      (@names ? (reserved_names => {map {$_=>1} @names}) : ()),
      verbose => 1
     );
  };
  if (!defined $pmltq) {
    $@ = "Empty query! Possible error - unable to find node in file" unless $@;
    die; # send error upper
  } else {
    print STDERR '['.localtime()."] Serving PMLTQ for $paths: $pmltq\n";
    binmode(select());
    Encode::_utf8_off($pmltq);
    print "HTTP/1.0 200 OK\r\n";
    print $cgi->header(-type => 'text/plain',
                       -charset => 'UTF-8',
                       # -Content_length => ((stat($fh))[7]),
                      );
    print $pmltq;
  }
}

1;