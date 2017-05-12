package Reaction::UI::Widget::Data;

use Reaction::UI::WidgetClass;
use namespace::clean -except => [qw(meta)];

extends 'Reaction::UI::Widget::Container';

before fragment widget {
  my $data = $_{viewport}->args;
  arg $_ => $data->{$_} for keys %$data;
};

1;

__END__

=head1 NAME

Reaction::UI::Widget::Data - Abstract class to render a data hash reference

=head1 DESCRIPTION

This takes the C<args> method return value of the viewport and populates the
arguments with names and values from that value.

=head1 FRAGMENTS

=head2 widget

Sets an argument for every key and value in the viewport's C<args> method return
value (which is expected to be a hash reference).

=head1 EXAMPLE LAYOUT

Assuming this hash reference:

  { first_name => "Foo", last_name => "Bar" }

we can access it in a layout set like this:

  =widget Data
  
  =for layout widget
  
  Hello [% last_name | html %], [% first_name | html %]!
  
  =cut

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
