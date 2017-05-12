package Parallel::parallel_map;

use 5.008;
our $VERSION = '0.02';

use strict;
use warnings;
use Parallel::DataPipe;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(parallel_map);


sub parallel_map(&@) {
    my ($code,@input) = @_;
    my (@result,@output);
    if (wantarray) {
        @output = (output=>sub {my ($r,$i) = @_;$result[$i] = $r;});
    }
    Parallel::DataPipe::run {
        input => \@input,
        process => $code,
        @output,
    };
    return wantarray?@result:();
}

1;

__END__

=head1 NAME

Parallel::parallel_map - map in parallel using all CPU cores

=head1 SYNOPSIS

  use Parallel::parallel_map;
  my @m2 = parallel_map {$_*2} 1..10000000;

=head1 DESCRIPTION

It does the same as map in perl, but using all CPU/cores.
Take into account that each iteration is executed as separate process i.e. changes of memory inside iterator will not affect
memory state of main thread.
Still there is some overhead on IPC, so to calculate $_*2 in parallel does not make practical sense.
Although if your iteration is more complex then that - you will win.
Do benchmarks to figure out.

It is implemented using Parallel::DataPipe.


=head2 EXPORT

parallel_map the same as map, but in parallel

=head2 BENCHMARKS

I have found Parallel::Iterator module at CPAN which basically does the same thing.
But it has much bigger overhead on IPC than this module.

 perl -MParallel::Iterator=iterate_as_array -MBenchmark -e'@a=1..10000;timethis(10,q{@m2=iterate_as_array(sub {$_[1]*2}, \@a)})'
 timethis 10:  4 wallclock secs ( 2.85 usr  0.67 sys +  2.83 cusr  0.83 csys =  7.19 CPU) @  1.39/s (n=10)

 perl -MParallel::parallel_map -MBenchmark -e'timethis(10,q{@m2=parallel_map {$_*2} 1..10000_00})'
 timethis 10:  5 wallclock secs ( 2.81 usr  0.19 sys +  4.51 cusr  2.13 csys =  9.64 CPU) @  1.04/s (n=10)

It's almost 100 times faster than Parallel::Iterator on this simple iteration.

=head1 SEE ALSO

Parallel::DataPipe,
Parallel::Loops,
MCE, POE,
Parallel::Iterator

=head1 AUTHOR

Oleksandr Kharchenko, <okharch@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Oleksandr Kharchenko

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
