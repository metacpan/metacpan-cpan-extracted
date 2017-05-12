package NetSDS::Util::Struct;
########################################################################
# Misc Struct routines
#
########################################################################

=head1 NAME

NetSDS::Util::Struct - data structure convertors

=head1 SYNOPSIS

	use NetSDS::Util::Struct;

	...

	my $str = dump_to_row($some_structure);


=head1 DESCRIPTION

NetSDS::Util::Struct module contains different utilities for data structures processing.

=cut

use 5.8.0;
use warnings 'all';
use strict;

use base 'Exporter';

use version; our $VERSION = "1.044";

our @EXPORT = qw(
  dump_to_string
  dump_to_row
  arrays_to_hash
  to_array
  merge_hash
);

use Scalar::Util qw(
  blessed
  reftype
);


#***********************************************************************

=head1 EXPORTED METHODS

=over

=item B<dump_to_string(...)>

Returns cleaned dump to scalar.

=cut

#-----------------------------------------------------------------------
sub dump_to_string {
	my $dmp = Data::Dumper->new( ( scalar(@_) > 1 ) ? [ \@_ ] : \@_, ['DUMP'] );
	$dmp->Terse(0);
	$dmp->Deepcopy(0);
	$dmp->Sortkeys(1);
	$dmp->Quotekeys(0);
	$dmp->Indent(1);
	$dmp->Pair(': ');
	$dmp->Bless('obj');
	return $dmp->Dump();
}

#***********************************************************************

=item B<dump_to_row(...)>

Returns cleaned dump to scalar.

=cut

#-----------------------------------------------------------------------
sub dump_to_row {

	my $str = dump_to_string(@_);

	if ( $str =~ s/^\s*\$DUMP\s+=\s+[{\[]\s+//s ) {
		$str =~ s/\s+[}\]];\s+$//s;
	} else {
		$str =~ s/^\s*\$DUMP\s+=\s+//s;
		$str =~ s/\s;\s+$//s;
	}
	$str =~ s/\$DUMP/\$/g;
	$str =~ s/\s+/ /g;
	$str =~ s/\\'/'/g;
	$str =~ s/\\undef/undef/g;
	$str =~ s/\\(\d)/$1/g;

	return $str;
}

#***********************************************************************

=item B<to_array($data)>

=cut

#-----------------------------------------------------------------------
sub to_array {
	my ($data) = @_;

	if ( is_ref_array($data) ) {
		return $data;
	} elsif ( is_ref_hash($data) ) {
		return [ keys %{$data} ];
	} elsif ( defined($data) ) {
		return [$data];
	} else {
		return $data;
	}
}

#***********************************************************************

=item B<arrays_to_hash($keys_ref, $values_ref)> - translate arrays to hash

Parameters: references to keys array and values array

Return: hash

If @$keys_ref is longer than @$values_ref - rest of keys filled with
C<undef> values.

If @$keys_ref is shorter than @$values_ref - rest of values are discarded.

If any of parameters isn't array reference then C<undef> will return.

Example:

	my %h = array2hash(['fruit','animal'], ['apple','horse']);

Result should be a hash:

	(
		fruit => 'apple',
		animal => 'horse'
	)

=cut

#-----------------------------------------------------------------------
sub arrays_to_hash {
	my ( $keys_ref, $values_ref ) = @_;

	return undef unless ( is_ref_array($keys_ref) and is_ref_array($values_ref) );

	my %h = ();

	for ( my $i = 0 ; $i < scalar(@$keys_ref) ; $i++ ) {
		$h{ $keys_ref->[$i] } = defined( $values_ref->[$i] ) ? $values_ref->[$i] : undef;
	}

	return %h;
}

#***********************************************************************

=item B<merge_hash($target, $source)> - merge two hashes

Parameters: references to target and source hashes.

This method adds source hash to target one and return value as a result.

=cut

#-----------------------------------------------------------------------
sub merge_hash {
	my ( $trg, $src ) = @_;

	while ( my ( $key, $val ) = each( %{$src} ) ) {
		if ( is_ref_hash($val) and is_ref_hash( $trg->{$key} ) ) {
			merge_hash( $trg->{$key}, $val );
		} else {
			$trg->{$key} = $val;
		}
	}

	return $trg;
}

#**************************************************************************
1;
__END__

=back

=head1 EXAMPLES

None

=head1 BUGS

Unknown yet

=head1 TODO

None

=head1 SEE ALSO

None

=head1 AUTHORS

Valentyn Solomko <pere@pere.org.ua>

=cut
