package Reaction::UI::Widget::Field::Array;

use Reaction::UI::WidgetClass;

use namespace::clean -except => [ qw(meta) ];


before fragment widget {
  arg 'label' => localized $_{viewport}->label;
};

implements fragment list {
  render 'item' => over $_{viewport}->value_names;
};

implements fragment item {
  arg 'name' => localized $_;
};

__PACKAGE__->meta->make_immutable;


1;

__END__;

=head1 NAME

Reaction::UI::Widget::Field::Array - A field representing an array of localised items

=head1 DESCRIPTION

See L<Reaction::UI::Widget::Field::Collection>, of which this widget is not a subclass.

=head1 FRAGMENTS

=head2 widget

renders C<label> and C<list> passing additional variable "viewport"

=head2 label

C<content> contains the viewport's label

=head2 list

renders fragment item over the viewport's C<value_names>

=head2 item

C<content> contains the value of the current item ($_ / $_{_})

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
