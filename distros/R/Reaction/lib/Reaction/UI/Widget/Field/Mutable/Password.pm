package Reaction::UI::Widget::Field::Mutable::Password;

use Reaction::UI::WidgetClass;

use namespace::clean -except => [ qw(meta) ];
extends 'Reaction::UI::Widget::Field::Mutable';



around fragment widget {
  call_next;
  arg field_type => 'password';
  arg field_value => ''; # no sending password to user. really.
};

__PACKAGE__->meta->make_immutable;


1;

__END__;

=head1 NAME

Reaction::UI::Widget::Field::Mutable::Password - A password input field

=head1 DESCRIPTION

See L<Reaction::UI::Widget::Field::Mutable>. Creates a password type input field
and never sets the current value as the field's value.

=head1 FRAGMENTS

=head2 widget

Sets C<field_type> to C<password> and C<field_value> to an empty string.

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
