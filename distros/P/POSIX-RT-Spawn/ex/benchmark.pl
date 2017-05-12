#!/usr/bin/env perl
use strict;
use warnings;

use Benchmark qw(cmpthese);
use Getopt::Long qw(:config auto_help);
use Pod::Usage;
use POSIX::RT::Spawn;

my $count = -1;
my $size  = 10;

GetOptions(
    'count|c=i' => \$count,
    'size|s=f'  => \$size,
) or pod2usage(2);

# Allocate memory to the process.
my $mem = '1' x int $size * 2 ** 20;

my @cmd = qw(true that);

cmpthese $count, {
    fork_exec => sub {
        my $pid = fork;
        if (0 == $pid) {
            exec @cmd;
        }
        elsif ($pid) {
            waitpid $pid, 0;
        }
    },
    spawn => sub {
        my $pid = spawn @cmd;
        waitpid $pid, 0;
    },
};

# TODO: benchmark overridden system and backticks.

exit;


__END__

=head1 NAME

benchmark.pl

=head1 SYNOPSIS

  benchmark.pl --count -1 --size 10

  Options:

    -c --count  Iteration count     (default: -1)
    -s --size   Process size in MiB (default: 10)

=cut
