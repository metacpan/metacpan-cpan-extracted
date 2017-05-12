use Test::More;

BEGIN {
    eval "use DBD::SQLite";
    plan skip_all => "DBD::SQLite is required to run this test" if $@;
}

use lib 't/lib';

plan tests => 10;

use_ok('MojoX::Session');

use NewDB;

my $dbh = NewDB->dbh;

my $session = MojoX::Session->new(store => [dbi => {dbh => $dbh}]);

# create
my $sid = $session->create;
ok($sid);
ok($session->flush);

# load
ok($session->load($sid));
is($session->sid, $sid);

# update
$session->data(foo => 'bar');
ok($session->flush);
ok($session->load($sid));
is($session->data('foo'), 'bar');

# delete
$session->expire;
ok($session->flush);
ok(not defined $session->load($sid));
