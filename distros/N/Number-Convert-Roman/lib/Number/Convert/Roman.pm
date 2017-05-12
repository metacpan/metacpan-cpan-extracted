package Number::Convert::Roman;

# Number::Convert::Roman - Roman-Arabic numeral converter

# Copyright (c) 2015 José Santos. All rights reserved.
# This program is free software. It can be redistributed and/or modified under 
# the same terms as Perl itself.

use 5.006;
use strict;
use warnings;

our $VERSION = '0.01';

my %ROMAN_ARABIC = ('I' => 1, 'V' => 5, 'X' => 10, 'L' => 50, 
										'C' => 100, 'D' => 500, 'M' => 1000);
my %ARABIC_ROMAN = map { $ROMAN_ARABIC{$_} => $_ } keys %ROMAN_ARABIC;
my ($THOUSANDS_OPEN, $THOUSANDS_CLOSE) = ('(', ')');

sub new { bless {}, shift; }

sub arabic {
	shift;
	my @roman = split //, shift;
	my ($number, $sum, $last, $thousands) = (0, 0, 0, 0);
	for (my $i = $#roman; $i >= 0; $i--) {
		if ($roman[$i] !~ /[$THOUSANDS_CLOSE$THOUSANDS_OPEN]/) {
			$number = $ROMAN_ARABIC{$roman[$i]};
			$sum += ($number >= $last ? 1 : -1) * ($number * 1000 ** $thousands);
			$last = $number;
		} elsif ($roman[$i] eq $THOUSANDS_CLOSE) {
			$last = 0;
			$thousands++;
		}
	}
	$sum;
}

sub roman {
	shift;
	my ($i, @arabic) = (-1, split //, shift);
	my @numbers = map { $i++; $_ > 0 ? $_ . '0' x ($#arabic - $i) : () } @arabic;
	my ($prefix, $x, $y, $first, $thousands, $zerofill);
	# break each number using roman logic and underscore prefix each power of 1000
	# e.g. 1000 -> _1; 3000 -> _1, _1, _1; 4000 -> _1, _5; 5000000 -> __5
	for ($i = 0; $i <= $#numbers; $i++) {
		$prefix = '';
		$first = substr $numbers[$i], 0, 1;
		$thousands = int(log($numbers[$i] / $first) / log(1000));
		$prefix = '_' x $thousands;
		$numbers[$i] /= 1000 ** $thousands;
		$zerofill = '0' x ((length $numbers[$i]) - 1);
		if ($first == 1 || $first == 5) {
			$numbers[$i] = $prefix . $numbers[$i];
		} elsif ($first >= 2 && $first <= 3) {	# replace [2-3]0* by 2-3 x _+10*
			splice @numbers, $i, 1;
			for (1 .. $first) {
				splice @numbers, $i, 0, $prefix . 1 . $zerofill;
			}
			$i += $first - 1;
		} elsif ($first == 4) {	# replace 40* by 10* and 50*
			splice @numbers, $i, 1;
			splice @numbers, $i++, 0, $prefix . 1 . $zerofill, $prefix . 5 . $zerofill;
		} elsif ($first >= 6 and $first <= 8) {	# replace [6-8]0* by 50* + 1-3 x +10*
			splice @numbers, $i, 1;
			for (6 .. $first) {
				splice @numbers, $i, 0, $prefix . 1 . $zerofill;
			}
			splice @numbers, $i, 0, $prefix . 5 . $zerofill;
			$i += ($first - 5);
		} elsif ($first == 9) {	# replace 90* by 10* and 50*
			splice @numbers, $i, 1;
			splice @numbers, $i++, 0, $prefix . 1 . $zerofill, $prefix . 10 . $zerofill;
		}
	}
	# replace each underscore prefixed number by its parenthesis surrounded version
	# e.g. _1 -> (I); _1, _1, _1 -> (III); _1, _5 -> (IV); __5 -> ((V))
	my ($result, $previous_level, $level, $number) = ('', -1, 0, '');
	for (@numbers) {
		($prefix, $number) = m/(_*)(.+)/;
		$level = length $prefix;
		if ($level != $previous_level) {
			if ($level < $previous_level) {
				$result .= $THOUSANDS_CLOSE x ($previous_level - $level);
			} elsif ($level > $previous_level) {
				$result .= '(' x $level;
			}
			$previous_level = $level;
		}
		$result .= $ARABIC_ROMAN{$number};
	}
	if ($level eq $previous_level) {
		$result .= $THOUSANDS_CLOSE x $level;
	}
	# replace all (I), (II) and (III) by M, MM and MMM, respectively
	$result =~ s/\((I+)\)/'M' x length $1/ge;
	$result;
}

1;

__END__

=head1 NAME

Number::Convert::Roman - Roman-Arabic numeral converter

=head1 SYNOPSIS

 use Number::Convert::Roman;

 $c = Number::Convert::Roman->new;

 print $c->arabic('IV'); # prints 4
 print $c->roman(4);     # prints IV

=head1 DESCRIPTION

B<Roman> converts natural numbers between Roman and Arabic numeral systems.

An extended notation consisting in surrounding powers of thousand by 
parenthesis is applied to Roman numerals equal or greater than 4000:

=over 4

=item * (IV) corresponds to 4000

=item * ((IV)) corresponds to 4000000

=item * ((IV)IV)IV corresponds to 4004004

=back

=head1 METHODS

=over 4

=item $object = Number::Convert::Roman->B<new>

Create a B<Roman> object.

=item $object->B<arabic>(F<$roman_numeral>)

Convert a Roman numeral into its corresponding Arabic one.

Return value: Arabic numeral corresponding to given Roman one.

Example:

 # convert IV to Arabic
 $object->arabic('IV');	# returns 4

=back

=over 4

=item $object->B<roman>(F<$arabic_numeral>)

Convert an Arabic numeral into its corresponding Roman one.

Return value: Roman numeral corresponding to given Arabic one.

Example:

 # convert 4 to Roman
 $converter->roman(4);	# returns IV

=back

=head1 EXAMPLES

A sample script using B<Number::Convert::Roman> can be found under the 
F<examples> directory included with this module.

=head1 VERSION

B<Number::Conver::Roman> version 0.01.

=head1 AUTHOR

Santos, José.

=head1 BUGS

Please report any bugs or feature requests to 
C<bug-number-convert-roman at rt.cpan.org>, or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Number-Convert-Roman>. 
The author will be notified and there will be automatic notification about 
progress on bugs as changes are made.

=head1 SUPPORT

Documentation for this module can be found with the following perldoc command:

    perldoc Number::Convert::Roman

Additional information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Number-Convert-Roman>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Number-Convert-Roman>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Number-Convert-Roman>

=item * Search CPAN

L<http://search.cpan.org/dist/Number-Convert-Roman/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2015 José Santos. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 DEDICATION

I dedicate B<Number::Convert::Roman> to Prof. Nené.

=cut
