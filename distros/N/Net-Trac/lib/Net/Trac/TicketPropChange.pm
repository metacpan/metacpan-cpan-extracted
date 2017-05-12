use strict;
use warnings;

package Net::Trac::TicketPropChange;
use Any::Moose;

=head1 NAME

Net::Trac::TicketPropChange - A single property change in a Trac ticket history entry

=head1 DESCRIPTION

A very simple class to represent a single property change in a history entry.

=head1 ACCESSORS

=head2 property

=head2 old_value

=head2 new_value

=cut

has property  => ( isa => 'Str', is => 'rw' );
has old_value => ( isa => 'Str', is => 'rw' );
has new_value => ( isa => 'Str', is => 'rw' );

=head1 LICENSE
    
Copyright 2008-2009 Best Practical Solutions.
    
This package is licensed under the same terms as Perl 5.8.8.
    
=cut

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;
