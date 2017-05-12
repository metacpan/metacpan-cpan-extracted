package Net::Radio::oFono::Helpers::Container;

use strict;
use warnings;

use 5.010;

use List::Util qw(first);
use List::MoreUtils qw(firstidx);
use Params::Util qw(_INSTANCE _ARRAY0 _CODELIKE);
use Scalar::Util qw(blessed refaddr);

=head1 NAME

Net::Radio::oFono::Helpers::Container - simple container providing typical container functions

=head1 DESCRIPTION

This package implements a class which will act as a container for items of
any type. The container can be forced to accept only classes of a specific
type.

=head1 INHERITANCE

  Net::Radio::oFono::Helpers::Container

=head1 METHODS

=head2 new

Instantiates a new container object.

B<Parameters>:

All parameters are optional.

=over 4

=item I<array-ref>

Reference to an array for managing items. B<Use with caution>, it can be
dangerous when two containers access the same list.

=item I<class-name>

Name of classes to restrict the type which can be added. Adding items which
are not of specified type (or derived), an exception is thrown via L<Assert>.

=back

=cut

sub new
{
    my $className      = shift;
    my $elements       = shift // [];
    my $restrictedType = shift;

    my $self = blessed($className) ? $className : bless( {}, $className );

    $elements = [] unless ( _ARRAY0($elements) );
    $self->{elements} = $elements;
    $self->{restrictedType} = $restrictedType, $self->{iteratorIndex} = 0;

    return $self;
}

sub _affirm_type
{
    my ( $self, $elem ) = @_;
    return affirm { _INSTANCE( $elem, $self->{restrictedType} ) }
    "parameter 0 violates type restriction to '" . $self->{restrictedType};
}

sub _add_to
{
    my ( $self, $elem, $ary ) = @_;
    my $refelem = refaddr($elem);
    defined( first( sub { refaddr($_) == $refelem; }, @{$ary} ) )
      and croak("element at parameter 0 is already hold");
    push( @{ _ARRAY0($ary) }, $elem );
    return;
}

=head2 add

Adds a new item to the container.

B<Parameters>:

=over 4

=item I<item>

List of items to add to the container.

=back

=cut

sub add
{
    my ( $self, $elem ) = @_;

    defined( $self->{restrictedType} ) and $self->_affirm_type($elem);

    $self->_add_to( $elem, $self->{elements} );

    return $self;
}

sub _remove_from
{
    my ( $self, $elem, $ary ) = @_;
    my $refelem = refaddr($elem);

    my $idx = firstidx( sub { refaddr($_) == $refelem; }, @{$ary} );
    0 <= $idx and splice( @{$ary}, $idx, 1 );

    return wantarray ? $elem : ( $elem, $idx );
}

sub _move_between
{
    my ( $self, $elem, $sary, $dary ) = @_;

    $self->_remove_from( $elem, $sary );
    $self->_add_to( $elem, $dary );

    return $elem;
}

=head2 remove

Removes an item from the container.

B<Parameters>:

=over 4

=item I<item>

Item to remove from the container.

=back

B<Returns>:

The removed element in scalar mode and and array containing the removed
element at position 0 and it's index in the managed list at index 1 in
array mode.

=cut

sub remove
{
    my ( $self, $elem ) = @_;

    defined( $self->{restrictedType} ) and $self->_affirm_type($elem);

    my $idx;
    ( undef, $idx ) = $self->_remove_from( $elem, $self->{elements} );

    return wantarray ? ( $elem, $idx ) : $elem;
}

sub _where
{
    my ( $self, $elem, $ary ) = @_;
    my $refelem = refaddr($elem);

    return firstidx( sub { refaddr($_) == $refelem; }, @{$ary} );
}

=head2 contains

Returns whether this container manages specified item or not, compared by
the item address (L<Scalar::Util::refaddr>).

B<Parameters>:

=over 4

=item I<item>

The item to search for being in this container or not

=back

B<Returns>:

Boolean value - either it's in there or not.

=cut

sub contains
{
    my ( $self, $elem ) = @_;

    defined( $self->{restrictedType} ) and $self->_affirm_type($elem);

    return 0 <= $self->_where($elem);
}

=head2 clear

Clears this container, resets iterator. For each item, explicitely remove
is called for clearing.

=cut

sub clear()
{
    my $self = $_[0];

    while ( 0 < scalar( @{ $self->{elements} } ) )
    {
        my $elem = $self->{elements}->[-1];

        # seems we have a destruction problem and there're remaining undefs ...
        # maybe odg (http://search.cpan.org/dist/ogd/) is a way out
        if ( defined($elem) )
        {
            $self->remove($elem);
        }
        else
        {
            pop( @{ $self->{elements} } );
        }
    }
    $self->{iteratorIndex} = 0;
    $self->{inIteration}   = 0;

    return $self;
}

=head2 is_empty

Returns true when the container is empty - false otherwise.

=head2 n_elements

Returns the number of elements contained.

=cut

sub is_empty()   { 0 == scalar( @{ $_[0]->{elements} } ); }
sub n_elements() { scalar( @{ $_[0]->{elements} } ); }

=head2 for_each

Calls given sub for each item once, with the item as only argument. It's not
recommended to use this method - it's here for compatibility reasons only.
A better way to do sth. for each item is to use the iterator operators.

=cut

sub for_each(&)
{
    my ( $self, $sub ) = @_;

    affirm { _CODELIKE($sub) } "Parameter at index 0 isn't coderef";

    foreach my $child ( @{ $self->{elements} } )
    {
        &{$sub}($child);
    }

    return $self;
}

sub DESTROY { $_[0]->clear(); }

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-radio-ofono at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Radio-oFono>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

If you think you've found a bug then please read "How to Report Bugs
Effectively" by Simon Tatham:
L<http://www.chiark.greenend.org.uk/~sgtatham/bugs.html>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Radio::oFono

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Radio-oFono>

If you think you've found a bug then please read "How to Report Bugs
Effectively" by Simon Tatham:
L<http://www.chiark.greenend.org.uk/~sgtatham/bugs.html>.

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Radio-oFono>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Radio-oFono>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Radio-oFono/>

=back

=head2 Where can I go for help with a concrete version?

Bugs and feature requests are accepted against the latest version
only. To get patches for earlier versions, you need to get an
agreement with a developer of your choice - who may or not report the
issue and a suggested fix upstream (depends on the license you have
chosen).

=head2 Business support and maintenance

For business support you can contact Jens via his CPAN email
address rehsackATcpan.org. Please keep in mind that business
support is neither available for free nor are you eligible to
receive any support based on the license distributed with this
package.

=head1 ACKNOWLEDGEMENTS

=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

#
1;    # Packages must always end like this
