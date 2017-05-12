package Reaction::UI::Widget::Container;

use Reaction::UI::WidgetClass;

use aliased 'Reaction::UI::ViewPort';

use namespace::clean -except => [ qw(meta) ];


our $child_name;

# somewhat evil. fragment returns ($name, $code) to pass to implements
# or a method modifier name, so [1] will get us just the code

# This is convenient to do here but DO NOT duplicate this code outside of
# the same dist as WidgetClass since it's internals-dependent.

my $child_fragment_method
  = (fragment container_child {
       arg '_' => $_{viewport}->$child_name;
       render 'viewport';
     })[1];

around _method_for_fragment_name => sub {
  my $orig = shift;
  my $self = shift;
  my ($fragment_name) = @_;
  if (defined($child_name)
      && $fragment_name eq $child_name) {
    return $self->$orig(@_) || $child_fragment_method;
  }
  return $self->$orig(@_);
};
  
before _fragment_widget => sub {
  my ($self, $do_render, $args, $new_args) = @_;
  my @contained_names = $self->_contained_names($args->{viewport});
  foreach my $name (@contained_names) {
    $new_args->{$name} ||= sub {
      local $child_name = $name;
      $self->render($name, @_);
    };
  }
};

implements _contained_names => sub {
  my ($self, $vp) = @_;
  my @names;
  foreach my $attr ($vp->meta->get_all_attributes) {
    next unless eval { $attr->type_constraint->name->isa(ViewPort) };
    my $name = $attr->name;
    next if ($name eq 'outer');
    push(@names, $name);
  }
  return @names;
};

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Reaction::UI::Widget::Container - Provide viewport attibutes in the current viewport

=head1 DESCRIPTION

This widget base class (with no corresponding layout set) will search the viewports
attributes for those that contain L<Reaction::UI::ViewPort> classes or subclasses.

These attributes will then be provided as arguments to the C<widget> fragment and
can be rendered by their attribute name.

=head1 FRAGMENTS

=head2 widget

Provides rendering callbacks to those attributes of the viewport that can contain
viewport objects as arguments to the C<widget> layout.

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
