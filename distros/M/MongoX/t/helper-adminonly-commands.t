use strict;
use warnings;
use Test::More;
use Data::Dumper;

my $host;
BEGIN {
    $host = 'localhost';
    # check test
    if (exists $ENV{MONGOD}) {
        $host = $ENV{MONGOD};
    }
    eval "use MongoX host => '$host', db => 'test'";
    if ($@) {
        plan skip_all => $@;
    }
    else {
        plan tests => 10;
    }
}

use MongoX::Helper ':admin';

ok(admin_fsync_lock,'admin_fsync_lock');
ok(admin_unlock,'admin_unlock');

my $result;

{
    $result = admin_server_status;
    ok($result->{uptime},'admin_server_status');
}
{
    $result = admin_build_info;
    like($result->{version},'/1\.\d\.\d+/','admin_build_info');
}
{
    $result = admin_diag_logging;
    ok(exists $result->{was},'admin_diag_logging');
    note 'diag logging level:'.$result->{was};
}
{
    $result = admin_get_cmd_line_opts;
    ok($result->{argv},'admin_get_cmd_line_opts');
}
{
    $result = admin_log_rotate;
    ok($result->{ok},'admin_log_rotate');
}

SKIP: {
    $result = admin_resync;
    skip $result,1 unless ref $result;
    ok($result->{ok},'admin_resync');
}

{
    $result = admin_sharding_state;
    ok(exists $result->{enabled},'admin_sharding_state');
}
{
    $result = admin_unset_sharding;
    ok($result->{ok},'admin_unset_sharding');
}

