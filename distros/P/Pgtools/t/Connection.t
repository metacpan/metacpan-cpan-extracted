use strict;
use warnings;

use Test::More;
use Test::Exception;
use Data::Dumper;

use_ok('Pgtools::Connection');
use Pgtools::Connection;

my $default = {
    "host"     => "localhost",
    "port"     => 5432,
    "user"     => "postgres",
    "password" => "",
    "database" => "postgres"
};

my $s = Pgtools::Connection->new($default);
ok $s;
isa_ok($s, "Pgtools::Connection");

is($s->{host}, "localhost");
is($s->{port}, 5432);
is($s->{user}, "postgres");
is($s->{password}, "");
is($s->{database}, "postgres");

# ///////////////
# set_args
# ///////////////

my $s1 = Pgtools::Connection->new($default);
$s1->set_args("192.168.33.21,5432,postgres,,");
is($s1->{host}, "192.168.33.21");
is($s1->{port}, 5432);
is($s1->{user}, "postgres");
is($s1->{password}, "");
is($s1->{database}, "postgres");

my $s2 = Pgtools::Connection->new($default);
$s2->set_args(",,postgres,password,");
is($s2->{host}, "localhost");
is($s2->{port}, 5432);
is($s2->{user}, "postgres");
is($s2->{password}, "password");
is($s2->{database}, "postgres");

my $s3 = Pgtools::Connection->new($default);
$s3->set_args("postgres-db.com,15432,pguser,,db1");
is($s3->{host}, "postgres-db.com");
is($s3->{port}, 15432);
is($s3->{user}, "pguser");
is($s3->{password}, "");
is($s3->{database}, "db1");

my $s4 = Pgtools::Connection->new($default);
dies_ok {$s4->set_args("postgres-db.com,15432,pguser,db1")} 'expect to die';

my $s5 = Pgtools::Connection->new($default);
dies_ok {$s5->set_args("")} 'expect to die';

my $s6 = Pgtools::Connection->new($default);
dies_ok {$s6->set_args("postgres-db.com,15432,pguser,,db1,")} 'expect to die';




done_testing;
