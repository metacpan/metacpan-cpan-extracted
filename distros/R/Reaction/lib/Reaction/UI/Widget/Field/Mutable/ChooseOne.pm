package Reaction::UI::Widget::Field::Mutable::ChooseOne;

use Reaction::UI::WidgetClass;

use namespace::clean -except => [ qw(meta) ];
extends 'Reaction::UI::Widget::Field::Mutable';



implements fragment option_is_required {
  if ($_{viewport}->value_is_required) {
    render 'option_is_required_yes';
  } else {
    render 'option_is_required_no';
  }
};

implements fragment option_list {
  render option => over $_{viewport}->value_choices;
};

implements fragment option {
  arg option_name => $_->{name};
  arg option_value => $_->{value};
};

implements fragment option_is_selected {
  if ($_{viewport}->is_current_value($_->{value})) {
    render 'option_is_selected_yes';
  } else {
    render 'option_is_selected_no';
  }
};

__PACKAGE__->meta->make_immutable;


1;

__END__;

=head1 NAME

Reaction::UI::Widget::Field::Mutable::ChooseOne - Choose one from a list of available values

=head1 DESCRIPTION

See L<Reaction::UI::Widget::Field::Mutable>. This widget provides the user with a 
field where he can select a single value from a list of many.

=head1 FRAGMENTS

=head2 field

Renders a series fragment C<option> for each C<value_choices> in the viewport

Additional varibles set: C<is_required> - Boolean, self-explanatory

=head2 option

C<content> is a dummy variable, but th additional variables C<v_value>, C<v_name>
and C<is_selected> are set

=head2 option_is_required

Renders either C<option_is_required_yes> or C<option_is_required_no> depending on
the viewport's C<value_is_required> attribute.

=head2 option_list

Renders the C<option> fragment over the viewport's C<value_choices>. This populates
the list of available values.

=head2 option_is_selected

Renders either C<option_is_selected_yes> or C<option_is_selected_no> depending on
if the viewport's C<is_current_value> method returns true on the current topic
arguments C<value> key.

=head1 LAYOUT SETS

=head2 base

  share/skin/base/layout/field/mutable/choose_one.tt

This layout set renders a C<select> element with the available values as C<option>s.

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
