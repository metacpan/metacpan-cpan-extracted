package t::useragent;
use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);
use Carp;

sub new {
  my ($class, $ref) = @_;
  $ref ||= {};
  $ref->{'mock'} ||= {};

  if(!exists $ref->{is_success}) {
    carp qq(Did you mean to leave ua->{'is_success'} unset?);
  }

  return bless $ref, $class;
}

sub mock {
  my ($self, $mock) = @_;
  if($mock) {
    $self->{mock} = $mock;
  }
  return $self->{mock};
}

sub last_request {
  my ($self, $last_request) = @_;
  if($last_request) {
    $self->{last_request} = $last_request;
  }
  return $self->{last_request};
}

sub get {
  my ($self, $uri) = @_;
  $self->{'uri'}   = $uri;
  print {*STDERR} qq[t::useragent::get $self->{uri}\n];
  return $self;
}

sub post {
  my ($self, $uri, %args) = @_;
  $self->{uri}            = $uri;
  $self->{last_request}   = \%args;
  print {*STDERR} qq[t::useragent::post $self->{uri}\n];
  return $self;
}

sub request     {
  my ($self, $req) = @_;
  $self->{uri} = $req->uri();
  $self->{last_request} = $req;
  print {*STDERR} qq[t::useragent::request $self->{uri}\n];
  return $self;
}

sub requests_redirectable {
  my $self = shift;
  return [];
}

sub content {
  my $self = shift;

  #########
  # try and auto-fetch out of the t/data/ folder
  #
  my ($plpath)  = $self->{uri} =~ m{https?://plazes\.com(.*)$}mx;
  if($plpath !~ /\.xml$/mx) {
    $plpath .= q[.xml];
  }
  my $test_data = qq[t/data$plpath];

  if(!-e $test_data) {
    croak qq(No mock data configured for '$test_data');
  }

  if($test_data =~ m|^t/|mx) {
    open my $fh, q(<), $test_data or croak qq(Error opening $test_data: $ERRNO);
    local $RS   = undef;
    my $content = <$fh>;
    close $fh;
    return $content;
  }

  return $test_data;
}

sub response    { my $self = shift; return $self; }
sub is_success  { my $self = shift; return $self->{'is_success'}; }
sub status_line { return 'error in t::useragent'; }

1;
