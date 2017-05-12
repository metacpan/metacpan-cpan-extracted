package Reaction::UI::Window;

use Reaction::Class;
use Reaction::UI::FocusStack;

use namespace::clean -except => [ qw(meta) ];


has ctx => (isa => 'Catalyst', is => 'ro', required => 1, weak_ref => 1);
has view_name => (isa => 'Str', is => 'ro', lazy_fail => 1);
has content_type => (isa => 'Str', is => 'rw', lazy_fail => 1);
has title => (isa => 'Str', is => 'rw', default => sub { 'Untitled window' });
has view => (
  # XXX compile failure because the Catalyst::View constraint would be
  # auto-generated which doesn't work with unions. ::Types::Catalyst needed.
  #isa => 'Catalyst::View|Reaction::UI::View',
  isa => 'Object', is => 'ro', lazy_build => 1
);
has focus_stack => (
  isa => 'Reaction::UI::FocusStack',
  is => 'ro', required => 1,
  default => sub { Reaction::UI::FocusStack->new },
);
sub _build_view {
  my ($self) = @_;
  return $self->ctx->view($self->view_name);
};
sub flush {
  my ($self) = @_;
  my $res = $self->ctx->res;
  if ( $res->status =~ /^3/ || ( defined $res->body && length($res->body) ) ) {
      $res->content_type('text/plain') unless $res->content_type;
      return;
  }
  $self->flush_events;
  $self->flush_view;
};
sub flush_events {
  my ($self) = @_;
  my $ctx = $self->ctx;

  #I really think we should make a copies of the parameter hashes here
  #and then as we handle events, delete ethem from the event hashref, so
  #that it thins down as it makes it down the viewport tree. which would
  #limit the number of events that get to the children viewports. it wont
  #save that many subcalls unless there is a lot of child_items, but it's
  #more about doing the correct thing. It also avoids children viewports
  #being able to see their parents' events, which leaves the door open for
  #abuse of the system.  thoughts anyone?

  foreach my $type (qw/query body/) {
    my $meth = "${type}_parameters";
    my $req_param = $ctx->req->$meth;
    my $param_hash = { 
        map {
            $_ =~ m/(^r.+\:\w+)\.(x|y)/ ? # for <input type="image"... buttons
              ( $1 => $req_param->{$_} )
              : ( $_ => $req_param->{$_} )
        } keys %$req_param
    }; # yeah, FocusStack deletes it
    my @param_keys = keys %$param_hash;
    if (@param_keys) {
        for (@param_keys) {
            utf8::decode($param_hash->{$_})
                unless (utf8::is_utf8($param_hash->{$_}));
        }
        $self->focus_stack->apply_events($param_hash);
    }
  }
};
sub flush_view {
  my ($self) = @_;
  my $res = $self->ctx->res;
  my $res_body = $self->view->render_window($self);
  utf8::encode($res_body) if utf8::is_utf8($res_body);
  $res->body($res_body);
  $res->content_type($self->content_type);
};

# required by old Renderer::XHTML
sub render_viewport {
  my ($self, $vp) = @_;
  return unless $vp;
  return $self->view->render_viewport($self, $vp);
};

__PACKAGE__->meta->make_immutable;


1;

=head1 NAME

Reaction::UI::Window - Container for rendering the UI elements in

=head1 SYNOPSIS

  my $window = Reaction::UI::Window->new(
    ctx => $ctx,
    view_name => $view_name,
    content_type => $content_type,
    title => $window_title,
  );

  # More commonly, as Reaction::UI::Controller::Root creates one for you:
  my $window = $ctx->stash->{window};

  # Resolve current events and render the view of the UI
  #  elements of this Window:
  # This is called by the end action of Reaction::UI::Controller::Root
  $window->flush();

  # Resolve current events:
  $window->flush_events();

  # Render the top ViewPort in the FocusStack of this Window:
  $window->flush_view();

  # Render a particular ViewPort:
  $window->render_viewport($viewport);

  # Or in a template:
  [% window.render_viewport(self.inner) %]

  # Add a ViewPort to the UI:
  $window->focus_stack->push_viewport('Reaction::UI::ViewPort');

=head1 DESCRIPTION

A Window object is created and stored in the stash by
L<Reaction::UI::Controller::Root>, it is used to contain all the
elements (ViewPorts) that make up the UI. The Window is rendered in
the end action of the Root Controller to make up the page.

To add L<ViewPorts|Reaction::UI::ViewPort> to the stack, use the
L<Reaction::UI::Controller/push_viewport> method. For more detailed
information, read the L<Reaction::UI::FocusStack> and
L<Reaction::UI::ViewPort> documentation.

=head1 ATTRIBUTES

These are set for you by L<Reaction::UI::Controller::Root/begin> from
your Root controller configuration.

=head2 ctx

=over

=item Arguments: $ctx?

=back

The current L<Catalyst> context object.

=head2 view_name

=over

=item Arguments: $viewname?

=back

Retrieve/set the name of the L<Catalyst::View> component used to render
this Window. If this has not been set, rendering the Window will fail.

=head2 content_type

=over

=item Arguments: $contenttype?

=back

Retrieve the content_type for the page. If this has not been set,
rendering the Window will fail.

=head2 title

=over

=item Arguments: $title?

=back

  [% window.title %]

Retrieve/set the title of this page, if not set, it will default to
"Untitled window".

=head2 view

=over

=item Arguments: none

=back

Retrieve the L<Catalyst::View> instance, this can be set, or will be
instantiated using the L<view_name> class.

=head2 focus_stack

=over

=item Arguments: none

=back

  $window->focus_stack->push_viewport('Reaction::UI::ViewPort');

Retrieve the L<stack|Reaction::UI::FocusStack> of
L<ViewPorts|Reaction::UI::ViewPorts> that contains all the UI elements
for this Window. Use L<Reaction::UI::FocusStack/push_viewport> on this
to create more elements. An empty FocusStack is created by the
Controller::Root when the Window is created.

=head1 METHODS

=head2 flush

=over

=item Arguments: none

=back

Synchronize the current events with all the L<Reaction::UI::ViewPort>
objects in the UI, then render the root ViewPort. This is called for
you by L<Reaction::UI::Controller::Root/end>.

=head2 flush_events

=over

=item Arguments: none

=back

Resolves all the current events, first the query parameters then the
body parameters, with all the L<Reaction::UI::ViewPort> objects in the
UI. This calls L<Reaction::UI::FocusStack/apply_events>. This method
is called by L<flush>.

=head2 flush_view

=over

=item Arguments: none

=back

Renders the page into the L<Catalyst::Response> body, unless the
response status is already set to 3xx, or the body has already been
filled. This is done via L<Reaction::UI::View/render_window>. This
method is called by L<flush>.

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
