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
use IPC::Open2;
use Test::More qw(no_plan);

BEGIN {
    use_ok('RPC::Object');
    use_ok('RPC::Object::Broker');
}

my ($out, $in);
my $pid = open2($out, $in, "$^X t/broker.pl");

my $name = 'Haha';
my $o = RPC::Object->new("localhost", 'new', 'TestModuleA', $name);
my @thr;
for (1..10) {
    push @thr, async {
        for (1..10) {
            $o->get_age();
        }
    };
}

for (@thr) {
    $_->join();
}

ok($o->get_age() == 100);

END {
    my $ko = RPC::Object->new("localhost", 'new', 'TestModuleC');
    eval { $ko->call_to_exit() };
}
