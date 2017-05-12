package Reaction::UI::FocusStack;

use Reaction::Class;

use namespace::clean -except => [ qw(meta) ];


has vp_head => (
  isa => 'Reaction::UI::ViewPort', is => 'rw',
  clearer => 'clear_vp_head',
);
has vp_tail => (
  isa => 'Reaction::UI::ViewPort', is => 'rw',
  clearer => 'clear_vp_tail',
);
has vp_count => (
  isa => 'Int', is => 'rw', required => 1, default => sub { 0 }
);
has loc_prefix => (isa => 'Str', is => 'rw', predicate => 'has_loc_prefix');
sub push_viewport {
  my ($self, $class, %create) = @_;
  my $tail = $self->vp_tail;
  my $loc = $self->vp_count;
  if ($self->has_loc_prefix) {
    $loc = join('-', $self->loc_prefix, $loc);
  }
  my $vp = $class->new(
    location => $loc,
    %create,
    focus_stack => $self,
    (defined $tail ? ( outer => $tail ) : ()), # XXX possibly a bug in immutable?
  );
  if ($tail) {           # if we already have a tail (non-empty vp stack)
    $tail->inner($vp);     # set the current tail's inner vp to the new vp
  } else {               # else we're currently an empty stack
    $self->vp_head($vp);   # so set the head to the new vp
  }
  $self->vp_count($self->vp_count + 1);
  $self->vp_tail($vp);
  return $vp;
};

sub pop_viewport {
  my ($self) = @_;
  my $head = $self->vp_head;
  confess "Can't pop from empty focus stack" unless defined($head);
  my $vp = $self->vp_tail;
  if ($vp eq $head) {
    $self->clear_vp_head;
    $self->clear_vp_tail;
  } else {
    $self->vp_tail($vp->outer);
  }
  $self->vp_count($self->vp_count - 1);
  return $vp;
};

sub pop_viewports_to {
  my ($self, $vp) = @_;
  1 while ($self->pop_viewport ne $vp);
  return $vp;
};

sub apply_events {
  my $self = shift;
  my $all_events = shift;
  my $vp = $self->vp_tail;

  while (defined $vp && keys %$all_events) {
    my $loc = $vp->location;
    my %vp_events = map { $_ => delete $all_events->{$_} }
      grep { /^${loc}[-:]/ } keys %$all_events;
    $vp->apply_events(\%vp_events);
    $vp = $vp->outer;
  }
};


__PACKAGE__->meta->make_immutable;


1;

=head1 NAME

Reaction::UI::FocusStack - A linked list of ViewPort-based objects

=head1 SYNOPSIS

  my $stack = Reaction::UI::FocusStack->new();

  # Or more commonly, in a Reaction::UI::RootController based
  # Catalyst Controller:
  my $stack = $ctx->focus_stack;

  # Add a new basic viewport inside the last viewport on the stack:
  my $vp = $stack->push_viewport('Reaction::UI::ViewPort' => 
                                  layout => 'xhtml'
                                );

  # Fetch the innermost viewport from the stack:
  my $vp = $stack->pop_viewport();

  # Remove all viewports inside a given viewport:
  $stack->pop_viewports_to($vp);

  # Create a named stack as a tangent to an existing viewport:
  my $newstack = $vp->create_tangent('somename');

  # Resolve current events using your stack:
  # This is called by Reaction::UI::RootController in the end action.
  $stack->apply_events($ctx, $param_hash);

=head1 DESCRIPTION

A FocusStack represents a list of related L<ViewPort|Reaction::UI::ViewPort>
objects. The L<Reaction::UI::RootController> creates an empty stack for you in
it's begin action, which represents the main thread/container of the page.
Typically you add new ViewPorts to this stack as the main parts of your page.
To add multiple parallel page subparts, create a tangent from the outer
viewport, and add more viewports as normal.

=head1 METHODS

=head2 new

=over

=item Arguments: none

=back

Create a new empty FocusStack. This is done for you in
L<Reaction::UI::RootController>.

=head2 push_viewport

=over

=item Arguments: $class, %options

=back

Creates a new L<Reaction::UI::ViewPort> based object and adds it to the stack.

The following attributes of the new ViewPort are set:

=over 

=item outer

Is set to the preceding ViewPort in the stack.

=item focus_stack

Is set to the FocusStack object that created the ViewPort.

=item location

Is set to the location of the ViewPort in the stack.

=back

=head2 pop_viewport

=over 

=item Arguments: none

=back

Removes the last/innermost ViewPort from the stack and returns it.

=head2 pop_viewports_to

=over 

=item Arguments: $viewport

=back

Pops all ViewPorts off the stack until the given ViewPort object
remains as the last item. If passed a $viewport not on the stack, this
will empty the stack completely (and then die complainingly).

TODO: Should pop_viewports_to check $vp->focus_stack eq $self first?

=head2 vp_head

=over

=item Arguments: none

=back

Retrieve the first ViewPort in this stack. Useful for calling
L<Reaction::UI::Window/render_viewport> on a
L<Reaction::UI::ViewPort/focus_tangent>.

=head2 vp_head

=over 

=item Arguments: none

=back

Retrieve the first ViewPort in this stack. Useful for calling
L<Reaction::UI::Window/render_viewport> on a
L<Reaction::UI::ViewPort/focus_tangent>.

=head2 vp_tail

=over 

=item Arguments: none

=back

Retrieve the last ViewPort in this stack. Useful for calling
L<Reaction::UI::Window/render_viewport> on a
L<Reaction::UI::ViewPort/focus_tangent>.

=head2 vp_count

=over 

=item Arguments: none

=back

=head2 loc_prefix

=head2 apply_events

=over 

=item Arguments: $ctx, $params_hashref

=back

Instruct each of the ViewPorts in the stack to apply the given events
to each of it's tangent stacks, and then to itself. These are applied
starting with the last/innermost ViewPort first.

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
