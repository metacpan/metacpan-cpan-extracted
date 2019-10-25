package PostgreSQLHosting::Provider::HCloud::API;

use utf8;
binmode(STDOUT, ":utf8");
use open qw/:std :utf8/;

use Moo;
use strictures 2;

BEGIN {
  use Path::Tiny qw(path);
  path("$ENV{HOME}/.hcloudapitoken")->touch;
  use LWP::UserAgent::Determined;
  use Net::hcloud ();
  $Net::hcloud::UA = LWP::UserAgent::Determined->new;
}


has api_key => (is => 'ro', required => 1);

sub BUILD {
  my ($self, $args) = @_;
  $Net::hcloud::token = $args->{api_key};
  $args;
}

sub AUTOLOAD {
  my ($method) = (our $AUTOLOAD =~ /([^:]+)$/);

  my $self = shift;

  return $self->$method if $self->can($method);

  return if $method eq 'DESTROY';

  my $routine = "Net::hcloud::$method";
  goto &$routine;
}
1;
