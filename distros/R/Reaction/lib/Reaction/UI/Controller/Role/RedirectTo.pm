package Reaction::UI::Controller::Role::RedirectTo;

use Moose::Role;

sub redirect_to {
  my ($self, $c, $to, $cap, $args, $attrs) = @_;

  $c->log->debug(
    "Using redirect_to is now deprecated and may be removed in the future."
  );

  #the confess calls could be changed later to $c->log ?
  my $action;
  my $reftype = ref($to);
  if( $reftype eq '' ){
    $action = $self->action_for($to);
    confess("Failed to locate action ${to} in " . blessed($self)) unless $action;
  } elsif($reftype eq 'ARRAY' && @$to == 2){ #is that overkill / too strict?
    $action = $c->controller($to->[0])->action_for($to->[1]);
    confess("Failed to locate action $to->[1] in $to->[0]" ) unless $action;
  } elsif( blessed $to && $to->isa('Catalyst::Action') ){
    $action = $to;
  } else{
    confess("Failed to locate action from ${to}");
  }

  $cap ||= $c->req->captures;
  $args ||= $c->req->args;
  $attrs ||= {};
  my $uri = $c->uri_for($action, $cap, @$args, $attrs);
  $c->res->redirect($uri);
}

1;

__END__;


=head1 NAME

Reaction::UI::Controller::Role::RedirectTo

=head1 DESCRIPTION

Provides a C<redirect_to> method, which aims to be a more convenient way to
create internal redirects vs C<Catalyst::uri_for> and C<Catalyst::Response::redirect>

=head1 DEPRECATION NOTICE

This method was separated out of L<Catalyst::Controller> to facilitate deprecation.
The behavior of this method is, by design, flawed and you should aim to replace
any instances of it in your codebase;

=head1 METHODS

=head2 redirect_to $c, 'action_name', \@captures, \@args, \%query_parms

=head2 redirect_to $c, $action_object, \@captures, \@args, \%query_parms

=head2 redirect_to $c, [ Controller_name => 'action_name' ], \@captures, \@args, \%query_parms

Will create a uri from the arguments given and redirect to it without detaching.
If captures and arguments are not explicitly given, the ones from the current
request will be used. If query-parameters are not given, none will be used.

The first argument after C<$c> cab be one of three, the name of an action present
in the controller returned by C<$c-E<gt>controller>, an action object, or an
array reference contraining 2 items, a controller name and an action name.

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
