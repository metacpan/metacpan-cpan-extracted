use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time usleep);

BEGIN { use_ok 'Protocol::OSC' }
my $p = Protocol::OSC->new;
my @spec = (time,[qw(/echo isfi 3 aaba 3.1 0)],[qw(/echo iii 3 1 0)]);

ok($p->parse($p->bundle(@spec))->[0] eq $spec[0], 'bundle in-out - datagram(udp)');
ok($p->parse($p->from_stream($p->to_stream($p->bundle(@spec))))->[0] eq $spec[0], 'bundle in-out - stream(tcp)');

$p->set_cb('/echo', sub {
    ok !defined($_[0]), 'process 1';
    ok $_[2]->type eq 'isfi', 'process 2';
});
$p->process($p->message(@{$spec[1]}));

done_testing;
