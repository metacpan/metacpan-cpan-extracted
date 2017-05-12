package Reaction::UI::Widget::Field::Mutable::ChooseMany;

use Reaction::UI::WidgetClass;

use namespace::clean -except => [ qw(meta) ];
extends 'Reaction::UI::Widget::Field::Mutable';



implements fragment action_buttons {
  foreach my $event (
    qw(add_all_values do_add_values do_remove_values remove_all_values)
      ) {
    arg "event_id_${event}" => event_id $event;
  }
};

implements fragment current_values {
  my $current_choices = $_{viewport}->current_value_choices;
  if( @$current_choices ){
    arg field_name => event_id 'value';
    render hidden_value => over $current_choices;
  } else {
    arg field_name => event_id 'no_current_value';
    arg '_' => {value => 1};
    render 'hidden_value';
  }
};

implements fragment selected_values {
  arg event_id_remove_values => event_id 'remove_values';
  render value_option => over $_{viewport}->current_value_choices;
};

implements fragment available_values {
  arg event_id_add_values => event_id 'add_values';
  render value_option => over $_{viewport}->available_value_choices;
};

implements fragment value_option {
  arg option_name => $_->{name};
  arg option_value => $_->{value};
};

implements fragment hidden_value {
  arg hidden_value => $_->{value};
};

__PACKAGE__->meta->make_immutable;


1;

__END__;

=head1 NAME

Reaction::UI::Widget::Field::Mutable::ChooseMany - Choose a number of items

=head1 DESCRIPTION

See L<Reaction::UI::Widget::Field::Mutable>

This needs a refactor to not be tied to a dual select box, but ENOTIME

=head1 FRAGMENTS

=head2 action_buttons

Sets the following events by the name C<event_id_$name> as arguments with their viewport 
event ids as values:

  add_all_values
  do_add_values
  do_remove_values
  remove_all_values

=head2 current_values

Renders the C<hidden_value> fragment to store the currently selected values either once
for every item in the viewport's C<current_value_choices> (with the C<field_name> argument
set to the viewport's event id for C<value>. Or, if no current values exist, uses the 
C<no_current_value> event id from the viewport and sets the topic argument C<_> to 1.

=head2 selected_values

Sets C<event_id_remove_values> to the viewport's event id for C<remove_values> and renders
the C<value_option> fragment over the viewport's C<current_value_choices>.

=head2 available_values

Sets C<event_id_add_values> to the viewport's event id for C<add_values> and renders
the C<value_option> fragment over the viewport's C<available_value_choices>.

=head2 value_option

Sets the C<option_name> argument to the current topic argument's C<name> key and the
C<option_value> to the current topic argument's C<value> key.

=head2 hidden_value

Sets C<hidden_value> to the current topic's C<value> key.

=head2 field

renders C<available_values>, C<action_buttons>, C<selected_values> and C<current_values>

=head1 LAYOUT SETS

=head2 base

  share/skin/base/layout/field/mutable/choose_many.tt

This layout set provides a table containing two lists separated by action buttons that
allow the user to add values from the available list to the selected list.

=head2 default

  share/skin/default/layout/field/mutable/choose_many.tt

Same as in the C<base> skin, except that after each action button a C<br> element will
be rendered.

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
