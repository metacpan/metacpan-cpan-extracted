package Random::RDTSC;

use strict;
use warnings;
require Exporter;
require DynaLoader;

our @ISA       = qw(Exporter DynaLoader);
our @EXPORT_OK = qw(get_rdtsc rdtsc_rand64);
our $VERSION   = '0.1';

bootstrap Random::RDTSC $VERSION;

1;

__END__

=head1 NAME

Random::RDTSC - Perl wrapper for RDTSC-based random number generation

=head1 SYNOPSIS

    use Random::RDTSC qw(get_rdtsc rdtsc_rand64);

    my $timestamp  = get_rdtsc();
    my $random_val = rdtsc_rand64();

    print "TSC: $timestamp, Random: $random_val\n";

=head1 DESCRIPTION

This module provides access to the C<get_rdtsc()> and C<rdtsc_rand64()>
functions from the C<rdtsc_rand> library, allowing for high-resolution
timestamps and random number generation based on the CPU's RDTSC instruction.

C<Random::RDTSC> is not vetted for true randomness. It is designed to be a
good starting point for other pseudo random number generators. If you use
the numbers from C<Random::RDTSC> as seeds for other PRNGs you can have good,
self-starting random numbers.

C<Random::RDTSC> is not seedable and thus I<not repeatable>. Repeatability
can be helpful for testing and validating code. You should use a seedable
PRNG to get repeatable random numbers.

Based on L<rdtsc_rand|https://github.com/scottchiefbaker/rdtsc_rand>.

=head1 FUNCTIONS

=head2 get_rdtsc

    my $tsc = get_rdtsc();

Returns the current timestamp counter value.

=head2 rdtsc_rand64

    my $rand = rdtsc_rand64();

Returns a 64-bit random number based on the timestamp counter.

=head1 CAVEATS

=head2 Are there better sources of randomness?

Most definitely. Your operating system gathers a source of entropy for
randomness that is very high quality. For cryptographic applications and
anything where true randomness is required you should use those instead.
C<Random::RDTSC> is designed to be quick and simple.

=head1 AUTHOR

Scott Baker - https://www.perturb.org/

=head1 LICENSE

This library is free software; you may redistribute it and/or modify it under the same terms as Perl itself.

=cut
