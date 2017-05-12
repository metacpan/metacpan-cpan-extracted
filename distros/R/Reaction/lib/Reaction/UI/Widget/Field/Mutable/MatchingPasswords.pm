package Reaction::UI::Widget::Field::Mutable::MatchingPasswords;

use Reaction::UI::WidgetClass;
use namespace::clean -except => [ qw(meta) ];

extends 'Reaction::UI::Widget::Field::Mutable::Password';

implements fragment check_field {
  arg 'field_id'   => event_id 'check_value';
  arg 'field_name' => event_id 'check_value';
  render 'field'; #piggyback!
};

implements fragment check_label {
  if (my $label = $_{viewport}->check_label) {
    arg label => localized $label;
    render 'label';
  }
};

__PACKAGE__->meta->make_immutable;

1;

__END__;

=head1 NAME

Reaction::UI::Widget::Field::Mutable::MatchingPasswords - Require double input of password

=head1 DESCRIPTION

This is a subclass of L<Reaction::UI::Widget::Field::Mutable::Password> implementing
a second field to repeat the password input.

=head1 FRAGMENTS

=head2 widget

Will render the C<check_field> fragment after the original C<widget> fragment.

=head2 check_field

Renders C<field> with C<field_id> and C<field_name> set to the viewport's C<check_value> event.

=head2 check_label

Localises the C<label> argument with a value from the viewport's C<check_label> attribute if
one is specified and renders the C<label> fragment.

=head1 LAYOUT SETS

=head2 base

  share/skin/base/layout/field/mutable/matching_passwords.tt

=head1 SEE ALSO

=over 4

=item * L<Reaction::UI::Widget::Field::Mutable::Password>

=back

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
