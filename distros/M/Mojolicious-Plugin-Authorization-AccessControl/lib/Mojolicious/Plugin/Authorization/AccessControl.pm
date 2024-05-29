package Mojolicious::Plugin::Authorization::AccessControl 0.02;
use v5.26;
use warnings;

# ABSTRACT: Integrate Authorization::AccessControl into Mojolicious

use Mojo::Base 'Mojolicious::Plugin';

use Authorization::AccessControl qw(acl);
use Readonly;
use Syntax::Keyword::Try;

use experimental qw(signatures);

Readonly::Scalar my $DEFAULT_PREFIX => 'authz';

sub register($self, $app, $args) {
  my $prefix   = $args->{prefix} // $DEFAULT_PREFIX;
  my $stash_ac = "_$prefix.request.accesscontrol";

  my $get_roles = sub($c) {$c->authn->current_user_roles};
  $get_roles = $args->{get_roles} // sub($c) {[]}
    if (exists($args->{get_roles}));
  die("get_roles must be a CODEREF/anonymous subroutine") if (defined($get_roles) && ref($get_roles) ne 'CODE');

  my $log_f = sub($m) {$app->log->info($m)};
  if (exists($args->{log})) {
    if (defined($args->{log})) {
      if (ref($args->{log}) && $args->{log}->isa('Mojo::Log')) {
        $log_f = sub($m) {$args->{log}->info($m)};
      }
    } else {
      $log_f = sub { }
    }
  }

  acl->hook(on_permit => sub ($ctx) {$log_f->("[Authorization::AccessControl] Granted: $ctx")});
  acl->hook(on_deny   => sub ($ctx) {$log_f->("[Authorization::AccessControl] Denied: $ctx")});

  my $get_ac = sub($c) {
    my $ac = acl;
    if ($c->tx->connection) {
      $c->stash($stash_ac => $ac->clone) unless (defined($c->stash($stash_ac)));
      $ac = $c->stash($stash_ac);
    }
    return $ac;
  };

  $app->helper(
    "$prefix.acl" => sub ($c) {
      return $get_ac->($c);
    }
  );

  $app->helper(
    "$prefix.role" => sub ($c, @params) {
      return $get_ac->($c)->role(@params);
    }
  );

  my @get_attrs;
  $app->helper(
    "$prefix.dynamic_attrs" => sub ($c, @params) {
      my $get_attrs = {handler => pop(@params)};
      $get_attrs->{resource} = shift(@params) if (@params);
      $get_attrs->{action}   = shift(@params) if (@params);
      push(@get_attrs, $get_attrs);
    }
  );

  my $get_get_attrs = sub ($resource, $action) {
    my @c = @get_attrs;
    @c = grep {!defined($_->{resource}) || $_->{resource} eq $resource} @c if (defined($resource));
    @c = grep {!defined($_->{action})   || $_->{action} eq $action} @c     if (defined($action));
    @c = sort {defined($b->{resource}) + defined($b->{action}) - (defined($a->{resource}) + defined($a->{action}))} @c;
    return ($c[0] // {})->{handler};
  };

  $app->helper(
    "$prefix.request" => sub ($c, $resource = undef, $action = undef) {
      my $roles = [];
      try {$roles = $get_roles->($c)} catch ($e) {
      }

      my $req = $get_ac->($c)->request->with_roles($roles->@*);
      $req = $req->with_action($action)     if (defined($action));
      $req = $req->with_resource($resource) if (defined($resource));
      if (my $f = $get_get_attrs->($resource, $action)) {
        $req = $req->with_get_attrs(sub($ctx) {$f->($c, $ctx)});
      }

      return $req;
    }
  );
}

=head1 NAME

Mojolicious::Plugin::Authorization::AccessControl - Integrate Authorization::AccessControl into Mojolicious

=head1 SYNOPSIS

  # in startup
  $app->plugin('Authorization::AccessControl' => {  
    get_roles => sub($c) { [$c->authn->current_user->roles] }
  });
  # static grants
  $app->authz->role('admin')
    ->grant(User => 'list')
    ->grant(User => 'create')
    ->grant(User => 'delete');
  
  $app->authz->dynamic_attrs(Book => list => undef);
  $app->authz->dynamic_attrs(Book => sub($c, $ctx) {
    return {
      book_id => $ctx->id,
      own     => $ctx->owner_id == $c->authn->current_user->id,
      deleted => defined($ctx->deleted_at)
    }
  });

  $app->hook(before_dispatch => sub($c) {
    #dynamic grants specific to current request
    $c->authz->grant(Book => 'delete', { book_id => $_->{book_id} })
      foreach ($c->model("GrantDelete")->for_user($c->authn->current_user))
  });

  # in controller
  use Authorization::AccessControl qw(acl);

  # static grants
  acl->role
    ->grant(Book => 'list', { deleted => 0 })
    ->grant(Book => "read")
    ->grant(Book => "edit", { own => 1 })
  ->role('admin')
    ->grant(Book => "list")
    ->grant(Book => "edit");

  sub list($self) {
    my $deleted = !!$self->param('include_deleted');
    $self->authz->request(Book => 'list')->with_attributes({ deleted => $deleted })->yield(sub() { 
      $deleted ? [$self->model("book")->all] : [$self->model("book")->all_except_deleted]
    })
    ->granted(sub ($books) {
      $self->render(json => $books)
    })
    ->denied(sub() {
      $self->render(status => 401, text => 'unauthorized')
    })
    ->null(sub() {
      $self->render(status => 404, text => 'notfound')
    })
  }

  sub get($self) {
    $self->authz->request(Book => 'read')->yield(sub() { 
      $self->model("book")->get($self->param('id')) 
    })
    ->granted(sub ($book) {
      $self->render(json => $book)
    })
    ->denied(sub () {
      $self->render(status => 401, text => 'unauthorized')
    })
    ->null(sub () {
      $self->render(status => 404, text => "book not found")
    })

  sub edit($self) {
    $self->authz->request(Book => 'edit')->yield(sub() { 
      $self->model("book")->get($self->param('id')) 
    })
    ->granted(sub ($book) {
      $book->update($self->req->body->json);
      $self->render(json => $book)
    })
    ->denied(sub () {
      $self->render(status => 401, text => 'unauthorized')
    })
    ->null(sub () {
      $self->render(status => 404, text => "book not found")
    })
  }

=head1 DESCRIPTION

This plugin ties together the functionality of L<Authorization::AccessControl>
with the L<Mojolicious> framework. In essence, this means:

=over

=item * roles are computed and attached to requests automatically based on the L</get_roles> function

=item * dynamic attributes callbacks can be registered and then they, too, will be used automatically at request time

=item * privilege grants can be static/permanent, or dynamic (per-request, from database, etc). Determination is automatically made based on context.

=item * all authorization checks are automatically logged to a Mojo::Log instance

=back

=head1 METHODS

L<Mojolicious::Plugin::Authorization::AccessControl> inherits all methods from 
L<Mojolicious::Plugin> and implements the following new ones

=head2 register

Register plugin in L<Mojolicious> application. Configuration via named arguments:

=head4 prefix

Configures the prefix used for the module's Mojolicious helper functions and 
stash values. This documentation assumes that it is left unchanged

Default: C<authz>

=head4 get_roles

Configures a callback for obtaining the roles relevent to the authorization
requests (i.e., the roles of the current user). The function receives one 
argument, the Mojolicious controller, and returns an ArrayRef of roles.

Default: C<sub($c) { $c-E<gt>current_user_roles }>

=head4 log

The L<Mojo::Log> instance that will be used to log Authorization activity in.
Set to undef to disable logging entirely.

Default: C<app-E<gt>log>

=head1 HELPERS

=head2 authz.acl

  $app->authz->acl()
  $c->authz->acl()

Returns the L<Authorization::AccessControl::ACL> instance, depending on context
If called on a request controller, returns an ACL specific to that request;
otherwise, returns the global L<Authorization::AccessControl::ACL/acl> instance.

The request-specific ACLs are constructed by cloning the global instance,
so you may populate the global instance with static grants, and then augment
them with dynamic request-specific grants.

=head2 authz.role

  $app->authz->role( $role = undef )
  $c->authz->role( $role = undef )

A shortcut for calling L<Authorization::AccessControl::ACL/role> on 
L</authz.acl>. Returns a dependent ACL instance contextualized on the given
C<$role> argument.

=head2 authz.request

  $c->authz->request( $resource = undef, $action = undef )

Creates and populates an L<Authorization::AccessControl::Request>. If 
C<$resource> and/or C<$action> are given, they are set on the request, but they
are also used for determining the 
L<Authorization::AccessControl::Request/with_get_attrs> function to assign.
The request's L<Authorization::AccessControl::Request/roles> are also configured,
using the L</get_roles> callback.

=head2 authz.dynamic_attrs

  $c->authz->dynamic_attrs($coderef)
  $c->authz->dynamic_attrs($resource, $coderef)
  $c->authz->dynamic_attrs($resource, $action, $coderef)

Registers a dynamic attributes callback function. C<$coderef> must be a CODEREF
or undefined. Dynamic attrs functions are searched from most to least specific,
so a general function may be overridden with a more-specific one, or blocked
entirely with an undefined entry, e.g.,

  $c->authz->dynamic_attrs(Book => sub($c, $ctx) { ... } );
  $c->authz->dynamic_attrs(Book => list => undef);

The first line declares a handler for attributes of Book resources. The second
clears the handler for the list action of Book resources, so the handler is used
for all Book resources, except for list actions.

=head1 AUTHOR

Mark Tyrrell C<< <mark@tyrrminal.dev> >>

=head1 LICENSE

Copyright (c) 2024 Mark Tyrrell

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut

1;

__END__
