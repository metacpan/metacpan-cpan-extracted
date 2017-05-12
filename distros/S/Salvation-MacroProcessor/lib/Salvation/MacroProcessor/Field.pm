use strict;

package Salvation::MacroProcessor::Field;

use Moose;

has 'description'	=> ( is => 'rw', isa => 'Salvation::MacroProcessor::MethodDescription', required => 1, handles => { ( map{ ( $_ )x2 } ( 'required_shares', 'required_filters', 'excludes_filters', 'connector_chain' ) ), ( name => 'method' ) } );

has 'value'	=> ( is => 'rw', isa => 'Any', required => 1 );


sub query        { $_[ 0 ] -> description() -> query       ( ( ( scalar( @_ ) == 2 ) ? $_[ 1 ] : () ), $_[ 0 ] -> value() ) }
sub postfilter { $_[ 0 ] -> description() -> postfilter( $_[ 1 ], $_[ 0 ] -> value() ) }


__PACKAGE__ -> meta() -> make_immutable();

no Moose;

-1;

__END__

# ABSTRACT: Query field object

=pod

=head1 NAME

Salvation::MacroProcessor::Field - Query field object

=head1 REQUIRES

L<Moose> 

=head1 METHODS

=head2 new

 Salvation::MacroProcessor::Field -> new(
 	description => $description,
	value => $value
 )

Constructor.

Returns B<Salvation::MacroProcessor::Field> instance.

All arguments documented at this section below.

=head2 description

 $field -> description()

Returns an appropriate L<Salvation::MacroProcessor::MethodDescription> instance for this field.

=head2 value

 $field -> value()

Returns a value supplied by you, or any other developer, as a condition for the filter.

=head2 postfilter

 $field -> postfilter( $object );

C<$object> is an object representing a single row of data returned by the query.

Shortcut for L<Salvation::MacroProcessor::MethodDescription>C<::postfilter>.

=head2 query

 $field -> query();
 $field -> query( $shares );

Shortcut for L<Salvation::MacroProcessor::MethodDescription>C<::query>.

=cut

