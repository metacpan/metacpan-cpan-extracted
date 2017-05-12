package Reaction::UI::ViewPort::Field::String::Fragment;

use Reaction::Class;
use MooseX::Types::Moose qw/Int/;
extends 'Reaction::UI::ViewPort::Field::String';

has max_length => (
  is => 'rw',
  isa => Int,
  required => 1,
  default => sub { 80 }
);

sub _build_layout { 'field/string' };

around _build_value_string => sub {
  my $super = shift;
  my $self = $_[0];
  my $string = $super->(@_);
  my $max_len = $self->max_length;
  if(length($string) > $max_len){
    $string = join('', substr( $string, 0, $max_len - 3 ), '...');
  }
  return $string;
};

1;

__END__;

=head1 DESCRIPTION

If it was possible to address the widgets in any way this wouldn't be necessary.

Ideally this would be a widget instead of a viewport. But there is currently no
way to implement this in a widget, because it is impossible to pass any
arguments to widgets.

Using this module will require subclassing the Object or Member Viewport to
override the builder classes for the field you desire to render as a string
fragment. If we ever get a way to pass arguments to layouts or widgets, this
will be greatly simplified. Don't hold your breath.

=cut
