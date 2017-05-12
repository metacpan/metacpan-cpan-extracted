use Test::More tests => 6;

use lib qw( t/lib t/lib/MyRDGC/lib );
use Data::Dump qw( dump );
use HTTP::Request::Common;
use IPC::Cmd qw( can_run );

SKIP: {
    skip "sqlite3 is not in PATH", 6 unless can_run('sqlite3');

use_ok('MyDB');
use_ok('Rose::DBx::Garden::Catalyst');

ok( my $garden = Rose::DBx::Garden::Catalyst->new(
        catalyst_prefix   => 'MyRDGC',
        garden_prefix     => 'MyRDBO',
        db                => MyDB->new,
        tt                => 1,
        use_db_name       => 'rdgctest',
        controller_prefix => 'CRUD',
        with_managers     => 0,
    ),
    "new garden"
);

ok( $garden->plant('t/lib/MyRDGC/lib'), "plant garden" );

# require since it won't exist till we bootstrap it
require Catalyst::Test;
Catalyst::Test->import('MyRDGC');

my $res;
ok( $res = request('/crud/rdgctest'), "get /crud/rdgctest" );

is( $res->headers->{status}, 200, "200 ok" );

# TODO more tests needed? or does CatalystX::CRUD::YUI cover
# all the bases?

}  # end SKIP
