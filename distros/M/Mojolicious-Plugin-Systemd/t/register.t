use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

my $unit_file
  = Mojo::File::curfile->sibling(qw(data foo.service))->to_abs->to_string;
plan skip_all => 'could not find foo.service' unless -r $unit_file;

delete $ENV{XDG_SESSION_ID};    # Smokers are run from systemd
note 'running outside of systemd';
use Mojolicious::Lite;
is eval { plugin 'systemd'; 1983 }, 1983, 'plugin loaded';

note 'force load plugin when called from systemd';
$ENV{XDG_SESSION_ID} = 42;
eval { plugin 'systemd' };
like $@, qr{SYSTEMD_UNIT_FILE_MISSING}, 'failed to load plugin';

$ENV{MOJO_SERVER_ACCEPTS}  = 1000;         # ignored
$ENV{SYSTEMD_SERVICE_FILE} = $unit_file;
is eval { plugin 'systemd'; 1983 }, 1983, 'plugin loaded';
is app->config->{hypnotoad}{accepts}, 31, 'default env_prefix';

done_testing;
