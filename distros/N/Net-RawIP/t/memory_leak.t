#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper    qw(Dumper);
use English         qw(-no_match_vars);
use Test::More;
use Net::RawIP;


plan skip_all  => "Proc::ProcessTable is needed for this test"
    unless eval "use Proc::ProcessTable; 1";
plan skip_all  => "Proc::ProcessTable does not support the size attribute on this platform"
    unless eval { my $s = get_process_size($$) };

plan tests => my $tests;


diag "Testing Net::RawIP v$Net::RawIP::VERSION";

# one can run this test giving a number on the command line
# 10,000 seems to be reasonable
my $count = shift || 10_000;
do_something();

my $start_size = get_process_size($$);
diag "Testing memory leak, running $count times";
diag "Start size: $start_size";

for (2..$count) {
    do_something();
}

sub do_something {
    my $n = Net::RawIP->new({ udp => {} });
    $n->set({
                ip => {
                            saddr => 1,
                            daddr => 2,
                    },
                udp => {
                            source => 0,
                            dest   => 100,
                            data   => 'payload',
                        },
                });
}
my $end_size = get_process_size($$);
my $size_change = $end_size - $start_size;
diag "End size: $end_size";
diag "Size change was: $size_change";
cmp_ok($size_change, '<', 200_000, 
    'normally it should be 0 but we are satisfied with 200,000 here, see comments in test file');
BEGIN { $tests += 1; }
# Once upon a time there was a memory leak on Solaris created by the above
# loop.
#
# In order to test the fix I created this test.
# On my development Ubuntu GNU/Linux machine the 
# starting size was around 7,300,000 bytes
# while the size change was constantly 1,064,960 
# no matter if I ran the loop 1000 times or 1,000,000 times 
# (though the latter took 5 minutes...)
# On another Linux machine (same OS, different HW) the change was 1,167,360
# On a Sun Solaris it was 1,220,608 (for 100, 1000, 10,000 and 100,000)
# I guess this the memory footprint of the external libraries that are loaded
# during run time and there is no memory leek.

# In order to reduce the external libraries issue I have changed the test.
# The first memory measurement is now done after calling the loop once
# This way the difference was only 122,880 on the Linux machine.
# I still cannot explain this change

# If you want, you can run the same test with different nuber of times:
# perl -Iblib/lib -Iblib/arch t/memory_leak.t 1000000



sub get_process_size {
    my ($pid) = @_;
    my $pt = Proc::ProcessTable->new;

    foreach my $p ( @{$pt->table} ) {
        return $p->size if $pid == $p->pid;
    }

    return
}

