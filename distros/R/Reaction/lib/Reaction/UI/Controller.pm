package Reaction::UI::Controller;

use Moose;
use Scalar::Util 'weaken';
use namespace::clean -except => [ qw(meta) ];

BEGIN { extends 'Catalyst::Controller'; }

has context => (is => 'ro', isa => 'Object', weak_ref => 1);
with(
  'Catalyst::Component::InstancePerContext',
  'Reaction::UI::Controller::Role::RedirectTo'
);

sub build_per_context_instance {
  my ($self, $c, @args) = @_;
  my $class = ref($self) || $self;
  my $newself =  $class->new($self->_application, {%{$self || {}}, context => $c, @args});
  return $newself;
}

sub push_viewport {
  my $self = shift;
  my $c = $self->context;
  my $focus_stack = $c->stash->{focus_stack};
  my ($class, @proto_args) = @_;
  my %args;
  if (my $vp_attr = $c->stack->[-1]->attributes->{ViewPort}) {
    if (ref($vp_attr) eq 'ARRAY') {
      $vp_attr = $vp_attr->[0];
    }
    if (ref($vp_attr) eq 'HASH') {
      $class = $vp_attr->{class} if defined $vp_attr->{class};
      %args = %{ $self->merge_config_hashes($vp_attr, {@proto_args}) };
    } else {
      $class = $vp_attr;
      %args = @proto_args;
    }
  } else {
    %args = @proto_args;
  }

  $args{ctx} = $c;

  if (exists $args{next_action} && !ref($args{next_action})) {
    $args{next_action} = [ $self, 'redirect_to', $args{next_action} ];
  }
  $focus_stack->push_viewport($class, %args);
}

sub pop_viewport {
  return shift->context->stash->{focus_stack}->pop_viewport;
}

sub pop_viewports_to {
  my ($self, $vp) = @_;
  return $self->context->stash->{focus_stack}->pop_viewports_to($vp);
}

sub make_context_closure {
  my($self, $closure) = @_;
  my $ctx = $self->context;
  weaken($ctx);
  return sub { $closure->($ctx, @_) };
}

1;

__END__;

=head1 NAME

Reaction::UI::Controller - Reaction Base Controller Class

=head1 SYNOPSIS

  package MyApp::Controller::Foo;
  use strict;
  use warnings;
  use parent 'Reaction::UI::Controller';

  use aliased 'Reaction::UI::ViewPort';

  sub foo: Chained('/base') Args(0) {
    my ($self, $ctx) = @_;

    $ctx->push_viewport(ViewPort,
      layout => 'foo',
    );
  }

  1;

=head1 DESCRIPTION

Base Reaction Controller class, subclass of L<Catalyst::Controller>.

=head1 ROLES CONSUMED

=over 4

=item L<Catalyst::Component::InstancePerContext>

=item L<Reaction::UI::Controller::Role::RedirectTo>

Please not that this functionality is now deprecated.

=back

=head1 METHODS

=head2 push_viewport $vp_class, %args

Creates a new instance of the L<Reaction::UI::ViewPort> class
($vp_class) using the rest of the arguments given (%args). Defaults of
the action can be overridden by using the C<ViewPort> key in the
controller configuration. For example to override the default number
of items in a CRUD list action:

__PACKAGE__->config(
                    action => {
                        list => { ViewPort => { per_page => 50 } },
    }
  );

The ViewPort is added to the L<Reaction::UI::Window>'s FocusStack in
the stash, and also returned to the calling code.

Related items:

=over

=item L<Reaction::UI::Controller::Root>
=item L<Reaction::UI::Window>

=back

TODO: explain how next_action as a scalar gets converted to the redirect arrayref thing

=head2 pop_viewport

=head2 pop_viewport_to $vp

Call L<Reaction::UI::FocusStack/pop_viewport> or
L<Reaction::UI::FocusStack/pop_viewport_to> on
the C<< $c->stash->{focus_stack} >>.

=head2 redirect_to $c, $to, $captures, $args, $attrs

Construct a URI and redirect to it.

$to can be:

=over

=item The name of an action in the current controller.

=item A L<Catalyst::Action> instance.

=item An arrayref of controller name and the name of an action in that
controller.

=back

$captures and $args default to the current requests $captures and
$args if not supplied.

=head2 make_context_closure

The purpose of this method is to prevent memory leaks.
It weakens the context object, often denoted $c, and passes it as the
first argument to the sub{} that is passed to the make_context_closure method.
In other words,

=over 4

make_context_closure returns sub { $sub_you_gave_it->($weak_c, @_)

=back

To further expound up this useful construct consider code written before
make_context_closure was created:

    on_apply_callback =>
        sub {
          $self->after_search( $c, @_ );
        }
    ),

This could be rewritten as:

    on_apply_callback => $self->make_context_closure(
        sub {
            my $weak_c = shift;
            $self->after_search( $weak_c, @_ );
        }
    ),

Or even more succintly:

    on_apply_callback => $self->make_context_closure(
        sub {
            $self->after_search( @_ );
        }
    ),

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
