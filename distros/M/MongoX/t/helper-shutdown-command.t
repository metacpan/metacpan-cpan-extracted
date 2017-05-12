use strict;
use warnings;
use Test::More;

BEGIN {
    plan skip_all => 'skip shutdown server test,$ENV{MONGOX_TEST_SHUTDOWN} not exits' unless exists $ENV{MONGOX_TEST_SHUTDOWN};
}

my $host = 'localhost';
# check test
if (exists $ENV{MONGOD}) {
    $host = $ENV{MONGOD};
}

plan tests => 1;
use MongoX;
use MongoX::Helper qw(admin_shutdown_server);

SKIP: {
    eval {
        boot host => $host,db => 'test';
    };
    skip $@,1 if $@;
    admin_shutdown_server;
    eval {
        add_connection host => $host, db => 'test2',id => 'check';
        use_connection 'check';
    };
    like($@, '/^couldn\'t connect to server/','admin_shutdown_server');
    diag('WARNING:MongoDB has been shutdown,you must restart it now.');
};

