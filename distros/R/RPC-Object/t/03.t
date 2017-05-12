use strict;
use warnings;
BEGIN {
    use Config;
    if (!$Config{useithreads}) {
        print ("1..0 # Skip: Perl not compiled with 'useithreads'\n");
        exit 0;
    }
}
use IPC::Open2;
use Test::More qw(no_plan);

BEGIN {
    use_ok('RPC::Object');
    use_ok('RPC::Object::Broker');
}

my ($out, $in);
my $pid = open2($out, $in, "$^X t/broker.pl");

my $o = RPC::Object->new("localhost", 'new', 'TestModuleC');

$o->call();
no warnings 'uninitialized';
ok($o->get_context() == undef);
scalar $o->call();
ok(!$o->get_context());
my @ret = $o->call();
ok($o->get_context());

END {
    eval { $o->call_to_exit() };
}

