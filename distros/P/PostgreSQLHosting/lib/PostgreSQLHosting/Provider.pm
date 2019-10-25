package PostgreSQLHosting::Provider;

use utf8;
binmode(STDOUT, ":utf8");
use open qw/:std :utf8/;

use Moo;
use strictures 2;

use String::CamelCase qw(camelize);
use Class::Load qw(load_class);
use Rex::Config;

sub make_instance {
  my ($self, $conf) = @_;
  my $provider_class_name
    = camelize($conf->{provider} or die 'Missing provider in config');
  my $provider
    = load_class('PostgreSQLHosting::Provider::' . $provider_class_name)->new(
    config         => $conf,
    ssh_public_key => Rex::Config::get_public_key,
    api_key        => $conf->{secret}
      || $ENV{PROVIDER_API_KEY}
      || die 'missing `secret` config parameter or PROVIDER_API_KEY env var'
    );
  return $provider;
}

1;
