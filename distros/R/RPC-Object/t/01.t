use strict;
use warnings;
BEGIN {
    use Config;
    if (!$Config{useithreads}) {
        print ("1..0 # Skip: Perl not compiled with 'useithreads'\n");
        exit 0;
    }
}
use threads;
use threads::shared;
use IPC::Open2;
use Test::More qw(no_plan);

BEGIN {
    use_ok('RPC::Object');
    use_ok('RPC::Object::Broker');
}

require_ok('RPC::Object');
require_ok('RPC::Object::Broker');

my ($out, $in);
my $pid = open2($out, $in, "$^X t/broker.pl");

my $name = 'Haha';
my $o = RPC::Object->new("localhost", 'new', 'TestModuleA', $name);
ok($o->get_name() eq $name);
ok($o->get_age() == 0);
ok($o->get_age() == 1);

my $o2 = RPC::Object->get_instance("localhost", 'TestModuleA');
ok($o2->get_name() eq $name);
ok($o2->get_age() == 2);
ok($o2->get_age() == 3);


$name = 'Hahaha';
my $o3 = RPC::Object->new("localhost", 'new', 'TestModuleA', $name);
ok($o3->get_name() eq $name);
ok($o3->get_age() == 0);
ok($o3->get_age() == 1);

$name = 'Haha';
my $o4 = RPC::Object->new("localhost", 'get_instance', 'TestModuleB', $name);
ok($o4->get_name() eq $name);
ok($o4->get_age() == 0);
ok($o4->get_age() == 1);

my $o5 = RPC::Object->get_instance("localhost", 'TestModuleB');
ok($o5->get_name() eq $name);
ok($o5->get_age() == 2);
ok($o5->get_age() == 3);

my $so = &share({});
$so->{obj} = &share(RPC::Object->new("localhost", 'new', 'TestModuleA', $name));
my $r = $so->{obj};
bless $r, 'RPC::Object';
ok($r->get_name() eq $name);
ok($r->get_age() == 0);
ok($r->get_age() == 1);

END {
    my $ko = RPC::Object->new("localhost", 'new', 'TestModuleC');
    eval { $ko->call_to_exit() };
}
