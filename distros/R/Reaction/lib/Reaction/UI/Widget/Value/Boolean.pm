package Reaction::UI::Widget::Value::Boolean;

use Reaction::UI::WidgetClass;

use namespace::clean -except => [ qw(meta) ];
extends 'Reaction::UI::Widget::Value';



__PACKAGE__->meta->make_immutable;


1;

__END__;

=head1 NAME

Reaction::UI::Widget::Value::Boolean

=head1 DESCRIPTION

See L<Reaction::UI::Widget::Value>

=head1 FRAGMENTS

=head2 value

C<content> contains the viewport's value_string

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
