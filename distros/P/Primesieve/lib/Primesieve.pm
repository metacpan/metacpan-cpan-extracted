package Primesieve;

use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
            generate_primes
            generate_n_primes
            nth_prime
            count_primes
            count_twins
            count_triplets
            count_quadruplets
            count_quintuplets
            count_sextuplets
            print_primes
            print_twins
            print_triplets
            print_quadruplets
            print_quintuplets
            print_sextuplets
            get_num_threads
            get_max_stop
            get_sieve_size
            set_sieve_size
            set_num_threads

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = @EXPORT_OK;

our $VERSION = '0.07';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Primesieve::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Primesieve', $VERSION);


1;
__END__

=head1 NAME

Primesieve - Perl extension for primesieve

=head1 SYNOPSIS

  use Primesieve;

  @primes = generate_primes (0,1000);

  my $iterator = Primesieve->new;
  2 == $iterator->next_prime;


=head1 DESCRIPTION

This modules gives you access to primesieve.

=head1 FUNCTIONS

=over 4

=item $it = Primesieve->new

Creates an iterator.

=item $it->next_prime

Returns the next prime.

=item $it->prev_prime

Returns the previous prime. (Only with primesieve version >= 6.0)

=item $it->skipto ($start, $stop_hint)

Set the position. 

=item @primes = generate_primes ($from, $to)

Returns a list of all primes in the specified range in list context.
In scalar context an array-reference is returned.

=item generate_n_primes ($n, $start)

Returns a list of the first C<n> primes >= C<start> in list context.
In scalar context an array-reference is returned.

=item $num = nth_prime ($n [,$start])

Find the nth prime.
if C<n> = 0 finds the 1st prime >= C<start>,
if C<n> > 0 finds the nth prime > C<start>,
if C<n> < 0 finds the nth prime < C<start> (backwards).

=item $num = count_primes ($start, $stop)

Counts primes within the given range.

=item $num = count_twins ($start, $stop)

Counts twin primes within the given range.

=item $num = count_triplets ($start, $stop)

Counts triple primes within the given range.

=item $num = count_quadruplets ($start, $stop)

Counts quadruplets primes within the given range.

=item $num = count_quintuplets ($start, $stop)

Counts quintuplets primes within the given range.

=item $num = count_sextuplets ($start, $stop)

Counts sextuplets primes within the given range.

=item $num = print_primes ($start, $stop)

Print primes within the given range to stdout.

=item $num = print_twins ($start, $stop)

Print twin primes within the given range to stdout.

=item $num = print_triplets ($start, $stop)

Print triple primes within the given range to stdout.

=item $num = print_quadruplets ($start, $stop)

Print quadruplets primes within the given range to stdout.

=item $num = print_quintuplets ($start, $stop)

Print quintuplets primes within the given range to stdout.

=item $num = print_sextuplets ($start, $stop)

Print sextuplets primes within the given range to stdout.

=item $num = get_max_stop ()

Returns the largest valid stop number for primesieve.

=item $num = get_sieve_size ()

Returns the current set sieve size in KiB.

=item $num = get_num_threads ()

Returns the current set number of threads.

=item set_sieve_size ($num)

Sets the sieve size in KiB.

=item set_num_threads ($num)

Sets the number of threads.

=back

=head1 SEE ALSO

=head1 AUTHOR

Stefan Traby, E<lt>stefan@hello-penguin.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by Stefan Traby

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.28.1 or,
at your option, any later version of Perl 5 you may have available.

