use strict;
use warnings;

use Test::More;
use Test::MockObject;
use Data::Dumper;
use DBI;

use_ok('Pgtools::Fingerprint');
use Pgtools::Fingerprint;

subtest 'fingerprint' => sub {
    my $filename = "";
    my $query = "SELECT * from users where id = 100";
    my $s = Pgtools::Fingerprint->new();

    ok $s;
    isa_ok($s, "Pgtools::Fingerprint");

    # ///////////////
    # symbolize_query
    # ///////////////

    is($s->symbolize_query("SELECT * FROM user WHERE id = 100;"), "SELECT * FROM user WHERE id = ?;");
    is($s->symbolize_query("SELECT * FROM user2 WHERE id = 100 LIMIT 3;"), "SELECT * FROM user2 WHERE id = ? LIMIT ?;");
    is($s->symbolize_query("SELECT * FROM user2 WHERE point =10.25;"), "SELECT * FROM user2 WHERE point =?;");
    is($s->symbolize_query("SELECT * FROM user2 WHERE point = +10.25;"), "SELECT * FROM user2 WHERE point = ?;");
    is($s->symbolize_query("SELECT * FROM user2 WHERE point =-10.25;"), "SELECT * FROM user2 WHERE point =?;");
    is($s->symbolize_query("SELECT * FROM user2 WHERE expression IS TRUE;"), "SELECT * FROM user2 WHERE expression IS ?;");
    is($s->symbolize_query("SELECT * FROM user2 WHERE expression IS true;"), "SELECT * FROM user2 WHERE expression IS ?;");
    is($s->symbolize_query("SELECT * FROM user2 WHERE expression IS FALSE;"), "SELECT * FROM user2 WHERE expression IS ?;");
};



done_testing;

