#!/usr/bin/perl
use strict;
use warnings;

use Benchmark qw/timethese cmpthese/;

use Sub::Sequence;
use List::MoreUtils qw/natatime/;

my $list_items = 1_000_000;
my @ID_LIST = (1..$list_items); @ID_LIST = ();
my $at_time    = 100;
my $result = timethese (5, {
    'seq'      => '&logic1;',
    'splice'   => '&logic2;',
    'natatime' => '&logic3;',
});

cmpthese $result;

sub logic1 {
    @ID_LIST = (1..$list_items);
    my $result = seq \@ID_LIST, $at_time, sub {
        1;
    };
}

sub logic2 {
    @ID_LIST = (1..$list_items);
    my $result;
    while ( my @list = splice(@ID_LIST, 0, $at_time) ) {
        push @{$result}, 1;
    }
}

sub logic3 {
    @ID_LIST = (1..$list_items);
    my $result;
    my $it = natatime $at_time, @ID_LIST;
    while ( my @list = $it->() ) {
        push @{$result}, 1;
    }
}

=pod

    SPECS:
        CentOS 5.5 Linux 2.6.39.1
        512MB memory
        Intel(R) Xeon(R) CPU L5520  @ 2.27GHz 4 core

    Benchmark: timing 5 iterations of natatime, seq, splice...
      natatime:  2 wallclock secs ( 1.89 usr +  0.06 sys =  1.95 CPU) @  2.56/s (n=5)
           seq:  1 wallclock secs ( 1.69 usr +  0.01 sys =  1.70 CPU) @  2.94/s (n=5)
        splice:  2 wallclock secs ( 1.48 usr +  0.00 sys =  1.48 CPU) @  3.38/s (n=5)
               Rate natatime      seq   splice
    natatime 2.56/s       --     -13%     -24%
    seq      2.94/s      15%       --     -13%
    splice   3.38/s      32%      15%       --

=cut
