use strict;

use Test::More;
use Mojo::File 'tempdir';

my $package;

my @methods = qw|authenticate authenticated config configfile disconnect drive list_drives|;
my @internal_methods = qw|_access_token _set_token _ua_delete _ua_get _ua_put _update_oauth_token|;

BEGIN {
  $package = 'Nuvol::Connector';
  use_ok $package or BAIL_OUT "Unable to load $package";
}

note 'Methods';
can_ok $package, $_ for @methods, @internal_methods;

note 'Illegal values';
my $configfile = tempdir()->child('testconfig.conf');

eval { $package->new($configfile) };
like $@, qr/Service missing!/, 'Can\'t create connector without service';

eval { $package->new($configfile, 'Inexistant') };
like $@, qr|Can't locate Nuvol/Inexistant/Connector|,
  'Can\'t create connector with inexistant implementation';

done_testing();
