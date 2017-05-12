package Reaction::UI::ViewPort::Field::Mutable::HiddenArray;

use Reaction::Class;
use namespace::clean -except => [ qw(meta) ];
use MooseX::Types::Moose qw/ArrayRef/;

extends 'Reaction::UI::ViewPort::Field';

with 'Reaction::UI::ViewPort::Field::Role::Mutable' => { value_type => 'ArrayRef' };

#has '+value' => (isa => ArrayRef);

around value => sub {
  my $orig = shift;
  my $self = shift;
  if (@_) {
    #this hsould be done with coercions
    $orig->($self, (ref $_[0] eq 'ARRAY' ? $_[0] : [ $_[0] ]));
    $self->sync_to_action;
  } else {
    $orig->($self);
  }
};
sub _empty_value { [] };
__PACKAGE__->meta->make_immutable;


1;

=head1 NAME

Reaction::UI::ViewPort::Field::Mutable::HiddenArray

=head1 DESCRIPTION

=head1 SEE ALSO

=head2 L<Reaction::UI::ViewPort::Field>

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
