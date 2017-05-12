package Net::Radio::oFono::Helpers::IteratableContainer;

use strict;
use warnings;

use 5.010;

use overload
  q(-=)   => \&decrease_by,
  q(+=)   => \&increase_by,
  q(@{})  => \&as_array,
  q(${})  => \&curr_item,
  q(<>)   => \&iterate,
  q(bool) => sub { 1 },
  q(0+)   => \&Net::Radio::oFono::Helpers::Container::n_elements;

=head1 NAME

Net::Radio::oFono::Helpers::IteratableContainer - simple container allows iterating over contained elements

=head1 DESCRIPTION

This package implements a class which will act as a container for items of
any type. In addition to Net::Radio::oFono::Helpers::Container it allows iterating
over it's content.

Per default following operators to the container instances are overloaded:

=over 4

=item C<@{}>

Gives plain access to the managed list of items.

=item C<bool>

Returns a boolean value (always true).

=item C<0+>

Returns the number of managed elements.

=item C<E<lt>E<gt>>

Iterates over all items and returns the currently selected on or undef,
if end of list is reached.

=item C<-=>

Reduces the iteration pointer by count.

=item C<+=>

Increases the iteration pointer by count.

=item C<${}>

Returns the currently selected item in an iteration.

=back

=head1 INHERITANCE

  Net::Radio::oFono::Helpers::IteratableContainer
  ISA Net::Radio::oFono::Helpers::Container

=head1 METHODS

=cut

sub _adjust_iter_idx
{
    my ( $self, $idx ) = @_;

    # ensure <> operator will take correctly next element
    if ( $self->{inIteration} && ( $self->{iteratorIndex} == $idx ) )
    {
        --$self->{iteratorIndex};
    }

    return;
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

    my $idx;
    ( undef, $idx ) = $self->SUPER::remove($elem);
    $self->_adjust_iter_idx($idx);

    return wantarray ? ( $elem, $idx ) : $elem;
}

=head2 decrease_by

Invoked via overloaded -= operator.

=cut

sub decrease_by
{
    my $self = shift;
    $self->{iteratorIndex} -= $_[0];
    $self->{iteratorIndex} < 0 and $self->{iteratorIndex} = 0;
    return $self;
}

=head2 increase_by

Invoked via overloaded += operator.

=cut

sub increase_by
{
    my $self = shift;
    $self->{iteratorIndex} += $_[0];
    $self->{iteratorIndex} > scalar( @{ $self->{elements} } )
      and $self->{iteratorIndex} = scalar( @{ $self->{elements} } );
    return $self;
}

=head2 as_array

Invoked by overloaded @{} operator.

=cut

sub as_array() { $_[0]->{elements}; }

=head2 iterate

Invoked by overloaded <> operator.

=cut

sub iterate()
{
    my $self = shift;
    my $elem;

    unless ( $self->{inIteration} )
    {
        ++$self->{inIteration};
        $self->{iteratorIndex} = -1;
    }

    if ( ++$self->{iteratorIndex} < scalar( @{ $self->{elements} } ) )
    {
        $elem = $self->{elements}->[ $self->{iteratorIndex} ];
    }
    else
    {
        --$self->{inIteration};
    }

    return $elem;
}

=head2 n_elements

Returns the number of elements contained.

=head2 curr_item

Invoked by overloaded ${} operator.

=cut

sub curr_item()
{
    $_[0]->{inIteration} and return $_[0]->{elements}->[ $_[0]->{iteratorIndex} ];
    return;
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
