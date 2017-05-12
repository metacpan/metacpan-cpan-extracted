package Test::Data::Array;
use strict;

use Exporter qw(import);
our $VERSION = '1.241';

our @EXPORT = qw( array_any_ok array_none_ok array_once_ok array_multiple_ok
	array_max_ok array_min_ok array_maxstr_ok array_minstr_ok array_sum_ok
	array_length_ok array_empty_ok
	array_sortedstr_ascending_ok array_sortedstr_descending_ok
	array_sorted_ascending_ok array_sorted_descending_ok
	);

use List::Util qw(sum min max minstr maxstr);

use Test::Builder;
my $Test = Test::Builder->new();

=encoding utf8

=head1 NAME

Test::Data::Array -- test functions for array variables

=head1 SYNOPSIS

use Test::Data qw(Array);

=head1 DESCRIPTION

=head2 Functions

=over 4

=item array_any_ok( ITEM, ARRAY [, NAME] )

Ok if any element of ARRAY is ITEM.

=cut

sub array_any_ok($\@;$) {
	my $element = shift;
	my $array   = shift;
	my $name    = shift || 'Array contains item';

	foreach my $try ( @$array ) {
		next unless $try eq $element;
		$Test->ok( 1, $name );
		return;
		}

	$Test->ok( 0, $name );
	}

=item array_none_ok( ITEM, ARRAY [, NAME] )

Ok if no element of ARRAY is ITEM.

=cut

sub array_none_ok($\@;$) {
	my $element = shift;
	my $array   = shift;
	my $name    = shift || 'Array does not contain item';

	foreach my $try ( @$array ) {
		next unless $try eq $element;
		$Test->ok( 0, $name );
		return;
		}

	$Test->ok( 1, $name );
	}

=item array_once_ok( ITEM, ARRAY [, NAME] )

Ok if only one element of ARRAY is ITEM.

=cut

sub array_once_ok($\@;$) {
	my $element = shift;
	my $array   = shift;
	my $name    = shift || 'Array contains item only once';

	my %seen = ();

	my $ok = 0;
	foreach my $item ( @$array ) { ++$seen{$item} }

	$ok = 1 if( defined $seen{$element} and $seen{$element} == 1 );

	$Test->ok( $ok, $name );
	}

=item array_multiple_ok( ITEM, ARRAY [, NAME] )

Ok if more than one element of ARRAY is ITEM.

=cut

sub array_multiple_ok($\@;$) {
	my $element = shift;
	my $array   = shift;
	my $name    = shift || 'Array contains item at least once';

	my %seen = ();
	foreach my $item ( @$array )
		{
		$seen{$item}++;
		}

	$seen{$element} > 1 ? $Test->ok( 1, $name ) : $Test->ok( 0, $name );
	}

=item array_max_ok( NUMBER, ARRAY [, NAME] )

Ok if all elements of ARRAY are numerically less than
or equal to NUMBER.

=cut

sub array_max_ok($\@;$) {
	my $item   = shift;
	my $array  = shift;
	my $name   = shift || 'Array maximum is okay';

	my $actual = max( @$array );

	$actual <= $item ? $Test->ok( 1, $name ) : $Test->ok( 0, $name );
	}

=item array_min_ok( NUMBER, ARRAY [, NAME] )

Ok if all elements of ARRAY are numerically greater than
or equal to NUMBER.

=cut

sub array_min_ok($\@;$) {
	my $item   = shift;
	my $array  = shift;
	my $name   = shift || 'Array minimum is okay';

	my $actual = min( @$array );

	$actual >= $item ? $Test->ok( 1, $name ) : $Test->ok( 0, $name );
	}

=item array_maxstr_ok( ITEM, ARRAY [, NAME] )

Ok if all elements of ARRAY are asciibetically less than
or equal to MAX.

=cut

sub array_maxstr_ok($\@;$) {
	my $item   = shift;
	my $array  = shift;
	my $name   = shift || 'Array maximum string is okay';

	my $actual = maxstr( @$array );

	$actual ge $item ? $Test->ok( 1, $name ) : $Test->ok( 0, $name );
	}

=item array_minstr_ok( ITEM, ARRAY [, NAME] )

Ok if all elements of ARRAY are asciibetically greater than
or equal to MAX.

=cut

sub array_minstr_ok($\@;$) {
	my $item   = shift;
	my $array  = shift;
	my $name   = shift || 'Array minimum string is okay';

	my $actual = minstr( @$array );

	$actual le $item ? $Test->ok( 1, $name ) : $Test->ok( 0, $name );
	}

=item array_sum_ok( SUM, ARRAY [, NAME] )

Ok if the numerical sum of ARRAY is SUM.

=cut

sub array_sum_ok($\@;$) {
	my $sum    = shift;
	my $array  = shift;
	my $name   = shift || 'Array sum is correct';

	my $actual = sum( @$array );

	$sum == $actual ? $Test->ok( 1, $name ) : $Test->ok( 0, $name );
	}

=item array_empty_ok( ARRAY [, NAME] )

Ok if the array contains no elements.

=cut

sub array_empty_ok(\@;$) {
	my $array = shift;
	my $name  = shift || 'Array is empty';

	$#$array == -1 ?  $Test->ok( 1, $name ) : $Test->ok( 0, $name );
	}


=item array_length_ok( ARRAY, LENGTH [, NAME] )

Ok if the array contains LENGTH number of elements.

=cut

sub array_length_ok(\@$;$) {
	my $array  = shift;
	my $length = shift;
	my $name   = shift || 'Array length is correct';

	$#$array == $length - 1 ?  $Test->ok( 1, $name ) : $Test->ok( 0, $name );
	}

=item array_sortedstr_ascending_ok( ARRAY, [, NAME] )

Ok if each succeeding element is asciibetically greater than or equal
to the one before.

=cut

sub array_sortedstr_ascending_ok(\@;$) {
	my $array = shift;
	my $name  = shift || 'Array is in ascending order';

	my $last_seen = 0;

	ELEMENT: foreach my $index ( 1 .. $#$array ) {
		if( $array->[ $index ] ge $array->[ $index - 1 ] ) {
			$last_seen = $index;
			next;
			}
		last;
		}

	$last_seen == $#$array ?
		$Test->ok( 1, $name )
			:
		$Test->ok( 0, $name );
	}

=item array_sortedstr_descending_ok( ARRAY, [, NAME] )

Ok if each succeeding element is asciibetically less than or equal to
the one before.

=cut

sub array_sortedstr_descending_ok(\@;$) {
	my $array = shift;
	my $name  = shift || 'Array is in descending order';

	my $last_seen = 0;

	ELEMENT: foreach my $index ( 1 .. $#$array ) {
		if( $array->[ $index ] le $array->[ $index - 1 ] )
			{
			$last_seen = $index;
			next;
			}
		last;
		}

	$last_seen == $#$array ?
		$Test->ok( 1, $name )
			:
		$Test->ok( 0, $name );
	}

=item array_sorted_ascending_ok( ARRAY, [, NAME] )

Ok if each succeeding element is numerically greater than or equal
to the one before.

=cut

sub array_sorted_ascending_ok(\@;$) {
	my $array = shift;
	my $name  = shift || 'Array is in ascending order';

	my $last_seen = 0;

	ELEMENT: foreach my $index ( 1 .. $#$array ) {
		if( $array->[ $index ] >= $array->[ $index - 1 ] ) {
			$last_seen = $index;
			next;
			}
		last;
		}

	$last_seen == $#$array ?
		$Test->ok( 1, $name )
			:
		$Test->ok( 0, $name );
	}

=item array_sorted_descending_ok( ARRAY, [, NAME] )

Ok if each succeeding element is numerically less than or equal to
the one before.

=cut

sub array_sorted_descending_ok(\@;$) {
	my $array = shift;
	my $name  = shift || 'Array is in descending order';

	my $last_seen = 0;

	ELEMENT: foreach my $index ( 1 .. $#$array ) {
		if( $array->[ $index ] <= $array->[ $index - 1 ] ) {
			$last_seen = $index;
			next;
			}
		last;
		}

	$last_seen == $#$array ?
		$Test->ok( 1, $name )
			:
		$Test->ok( 0, $name );
	}

=back

=head1 SEE ALSO

L<Test::Data>,
L<Test::Data::Scalar>,
L<Test::Data::Function>,
L<Test::Data::Hash>,
L<Test::Builder>

=head1 SOURCE AVAILABILITY

This source is in Github:

	https://github.com/briandfoy/test-data

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2002-2016, brian d foy <bdfoy@cpan.org>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

"bumble bee";
