package Number::Spice;
# $Id: Spice.pm,v 1.7 2000/09/22 15:32:04 verhaege Exp $
use strict;
use vars qw($RE_NUMBER $RE_SPICE_SUFFIX $RE_SPICE_NUMBER @RE_SUFFIX_VAL
	    $VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS);
use Exporter;
use base qw(Exporter);
$VERSION = '0.011';
@EXPORT = ();
@EXPORT_OK = qw(
  $RE_NUMBER $RE_SPICE_SUFFIX $RE_SPICE_NUMBER
  pattern is_spice_number split_spice_number suffix_value 
  spice_to_number number_to_spice normalize_spice_number
);
%EXPORT_TAGS = (
  convert => [qw(spice_to_number number_to_spice normalize_spice_number)],
  re      => [qw($RE_NUMBER $RE_SPICE_SUFFIX $RE_SPICE_NUMBER)],
  all     => \@EXPORT_OK,
);

BEGIN {
    # regular expression matching a plain number
    $RE_NUMBER = qr/
	(?<!\w)                         # start of a number, not the continuation of an identifier like 'cap12'
	[+-]?                           # optional sign
        (?:(?:\d+(?:\.\d*)?)|(?:\.\d+)) # mantissa
        (?:e[+-]?\d+)?                  # optional exponent
	/ix;

    # regular expression matching a spice suffix (special care is taken not to match an exponent)
    $RE_SPICE_SUFFIX = qr/
	(?:[a-df-z][a-z]*) # any word not starting with E
	|(?:e[a-z]+)       # OR an E followed by other characters
	/ix;

    # regular expression matching a spice number
    $RE_SPICE_NUMBER = qr/${RE_NUMBER}${RE_SPICE_SUFFIX}?\b/;

    # list of known spice suffices (as regular expressions) with their numerical value
    @RE_SUFFIX_VAL = (
      [qr/^t/i,            1e12], # tera
      [qr/^g/i,             1e9], # giga
      [qr/^(?:x|(?:meg))/i, 1e6], # mega
      [qr/^k/i,             1e3], # kilo
      [qr/^m(?!il)/i,      1e-3], # milli
      [qr/^u/i,            1e-6], # micro
      [qr/^n/i,            1e-9], # nano
      [qr/^p/i,           1e-12], # pico
      [qr/^f/i,           1e-15], # femto
      [qr/^a/i,           1e-18], # atto
      [qr/^mil/i,       2.54e-5], # mil (1/1000 inch)
    );
}

sub pattern {
    return $RE_SPICE_NUMBER;
}

sub is_spice_number {
    return $_[0] =~ /^\s*${RE_SPICE_NUMBER}\s*$/; # delimiting whitespace is allowed
}

sub split_spice_number {
    my $str = shift;
    if($str =~ /^\s*($RE_NUMBER)($RE_SPICE_SUFFIX?)\s*$/) { # the suffix is optional
        return ($1,$2 || ''); 
    }
    else { # not a spice number
	return wantarray ? () : undef; 
    }
}

sub suffix_value {
    my $suffix = shift;

    # try all known suffices
    foreach(@RE_SUFFIX_VAL) {
	return $_->[1] if $suffix =~ $_->[0];
    }

    # Not a recognized suffix.
    # It is standard spice policy to discard the suffix in this case,
    # which corresponds to a multiplication with 1.0.
    return 1;
}

sub spice_to_number {
    my $spice_number = shift;
    defined($spice_number) or 
	die "No argument given to spice_to_number()";

    my ($number,$suffix) = split_spice_number($spice_number) or
	die "Not a spice number: `$spice_number'";

    return $number * suffix_value($suffix);
}

sub number_to_spice {
    my $number = shift;
    my $abs_number = abs($number);
    my $suffix = '';

    # find the appropriate suffix
    foreach(
      [1e12,  't'],
      [1e9,   'g'],
      [1e6,   'meg'],
      [1e3,   'k'],
      [1e0,    ''], # if not introduced, 3.14 would be converted to '3140m' !!
      [1e-3,  'm'],
      [1e-6,  'u'],
      [1e-9,  'n'],
      [1e-12, 'p'],
      [1e-15, 'f'],
      [1e-18, 'a'],
    ) {
	if($abs_number >= $_->[0]) {
	    $number /= $_->[0];
	    $suffix = $_->[1];
	    last;
	}
    }
    # in case $abs_number < 1E-18, the suffix remains ''

    # format the adjusted number and suffix into a string
    return sprintf("%g$suffix",$number);
}

sub normalize_spice_number {
    return number_to_spice(spice_to_number($_[0]));
}

1;

__END__

=head1 NAME

Number::Spice - handling of Spice number strings

=head1 SYNOPSIS

    use Number::Spice qw(:convert);

    print spice_to_number('5u');      # 5E-6
    print spice_to_number('1.0e4k');  # 1.0E7

    print number_to_spice(1.0e12); # 1T
    print number_to_spice(1.0e-2); # 10M (i.e. milli, not mega!)

=head1 DESCRIPTION

Number::Spice was written to support the number format used in the syntax
for netlists for the spice electrical circuit simulator. This number
format is also used in other applications, even in different fields.
Number::Spice can be used to any purpose, and does not require the
installation of the spice simulator.

Spice syntax provides a shortcut for writing down numbers in scientific 
notation, by appending a suffix to the value which corresponds to a
numeric multiplier. The following table lists the minimal suffices and
the corresponding multiplier:

	T	1.0E12
	G	1.0E9
	MEG	1.0E6
	X	1.0E6
	K	1.0E3
	M	1.0E-3
	MIL	2.54E-5 (i.e. 1/1000 inch)
	U	1.0E-6
	N	1.0E-9
	P	1.0E-12	
	F	1.0E-15
	A	1.0E-18


=head1 USAGE

=head2 FUNCTIONS

The following functions are provided. 
All functions are available for exporting.

=over 2

=item pattern

Returns the regular expression matching a Spice number.

=item is_spice_number($spice_number)

Returns true is the given string matches a Spice number after removal of 
leading and trailing whitespace. Note that a plain number, i.e. without literal
suffix, is also accepted as a valid Spice number.

=item split_spice_number($spice_number)

Examines a string and returns a list holding a number and a spice suffix 
if the string holds a valid spice number. Returns undef otherwise.

Note that a regular number is also considered to be a spice number, 
and an empty string will be returned as the suffix in this case.

=item suffix_value($suffixc)

Returns the value of a given spice suffix, 
e.g. suffix_value('giga') yields 1.0E9.

=item spice_to_number($spice_number)

Returns a regular number represented by the given spice number. 
spice_to_number() will die() if the given number is not a spice number.

=item number_to_spice($number)

Returns the shortest spice number representing the given number. 
Note that no conversion to B<mil> will be attempted, 
and numbers smaller than 1.0E-18 will not get a suffix.

=item normalize_spice_number($spice_number)

Converts a spice number to its shortest form by invoking 
spice_to_number() and number_to_spice().

=back

=head2 REGULAR EXPRESSIONS

In addition to the methods, the following scalars representing regular
expressions are also made available for exporting:

=over 2

=item C<$RE_NUMBER>

matches a regular number

=item C<$RE_SPICE_SUFFIX>

matches any spice suffix

=item C<$RE_SPICE_NUMBER>

matches a spice number. Note that a regular number is considered a spice number
with no suffix. If you need to check for pure spice numbers, i.e. numbers with
a literal suffix, check with C</$RE_NUMBER$RE_SPICE_SUFFIX\b/> instead.

=back

=head2 EXPORT TAGS

The functions and regular expressions are tagged into the following groups
for easy importing:

=over 2

=item B<convert>

spice_to_number(), number_to_spice() and normalize_spice_number()

=item B<re>

C<$RE_NUMBER>, C<$RE_SPICE_SUFFIX> and C<$RE_SPICE_NUMBER>

=item B<all>

All conversion functions and regular expressions

=back

=head1 SEE ALSO

More info on the Spice format is given in the on-line Spice3 manual
at the University of Exeter, located at
http://newton.ex.ac.uk/teaching/CDHW/Electronics2/userguide/sec2.html#2

And to those who were looking for numbers on the Spice Girls, but unfortunately
stranded here, take a peek at their official home page: 
http://c3.vmg.co.uk/spicegirls/ ;-)

=head1 AUTHOR

Wim Verhaegen E<lt>wim.verhaegen@ieee.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2000 Wim Verhaegen. All rights reserved. 
This program is free software; you can redistribute
and/or modify it under the same terms as Perl itself.

=cut

