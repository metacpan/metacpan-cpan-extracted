# NAME

Mojolicious::Plugin::Authorization::AccessControl - Integrate Authorization::AccessControl into Mojolicious

# SYNOPSIS

    # in startup
    $app->plugin('Authorization::AccessControl' => {  
      get_roles => sub($c) { [$c->current_user->roles] }
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
        own     => $ctx->owner_id == $c->current_user->id,
        deleted => defined($ctx->deleted_at)
      }
    });

    $app->hook(before_dispatch => sub($c) {
      #dynamic grants specific to current request
      $c->authz->grant(Book => 'delete', { book_id => $_->{book_id} })
        foreach ($c->model("GrantDelete")->for_user($c->current_user))
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

# DESCRIPTION

This plugin ties together the functionality of [Authorization::AccessControl](https://metacpan.org/pod/Authorization%3A%3AAccessControl)
with the [Mojolicious](https://metacpan.org/pod/Mojolicious) framework. In essence, this means:

- roles are computed and attached to requests automatically based on the ["get\_roles"](#get_roles) function
- dynamic attributes callbacks can be registered and then they, too, will be used automatically at request time
- privilege grants can be static/permanent, or dynamic (per-request, from database, etc). Determination is automatically made based on context.
- all authorization checks are automatically logged to a Mojo::Log instance

# METHODS

[Mojolicious::Plugin::Authorization::AccessControl](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AAuthorization%3A%3AAccessControl) inherits all methods from 
[Mojolicious::Plugin](https://metacpan.org/pod/Mojolicious%3A%3APlugin) and implements the following new ones

## register

Register plugin in [Mojolicious](https://metacpan.org/pod/Mojolicious) application. Configuration via named arguments:

#### prefix

Configures the prefix used for the module's Mojolicious helper functions and 
stash values. This documentation assumes that it is left unchanged

Default: `authz`

#### get\_roles

Configures a callback for obtaining the roles relevent to the authorization
requests (i.e., the roles of the current user). The function receives one 
argument, the Mojolicious controller, and returns an ArrayRef of roles.

Default: `sub($c) { $c->current_user_roles }`

#### log

The [Mojo::Log](https://metacpan.org/pod/Mojo%3A%3ALog) instance that will be used to log Authorization activity in.
Set to undef to disable logging entirely.

Default: `app->log`

# HELPERS

## authz.acl

    $app->authz->acl()
    $c->authz->acl()

Returns the [Authorization::AccessControl::ACL](https://metacpan.org/pod/Authorization%3A%3AAccessControl%3A%3AACL) instance, depending on context
If called on a request controller, returns an ACL specific to that request;
otherwise, returns the global ["acl" in Authorization::AccessControl::ACL](https://metacpan.org/pod/Authorization%3A%3AAccessControl%3A%3AACL#acl) instance.

The request-specific ACLs are constructed by cloning the global instance,
so you may populate the global instance with static grants, and then augment
them with dynamic request-specific grants.

## authz.role

    $app->authz->role( $role = undef )
    $c->authz->role( $role = undef )

A shortcut for calling ["role" in Authorization::AccessControl::ACL](https://metacpan.org/pod/Authorization%3A%3AAccessControl%3A%3AACL#role) on 
["authz.acl"](#authz-acl). Returns a dependent ACL instance contextualized on the given
`$role` argument.

## authz.request

    $c->authz->request( $resource = undef, $action = undef )

Creates and populates an [Authorization::AccessControl::Request](https://metacpan.org/pod/Authorization%3A%3AAccessControl%3A%3ARequest). If 
`$resource` and/or `$action` are given, they are set on the request, but they
are also used for determining the 
["with\_get\_attrs" in Authorization::AccessControl::Request](https://metacpan.org/pod/Authorization%3A%3AAccessControl%3A%3ARequest#with_get_attrs) function to assign.
The request's ["roles" in Authorization::AccessControl::Request](https://metacpan.org/pod/Authorization%3A%3AAccessControl%3A%3ARequest#roles) are also configured,
using the ["get\_roles"](#get_roles) callback.

## authz.dynamic\_attrs

    $c->authz->dynamic_attrs($coderef)
    $c->authz->dynamic_attrs($resource, $coderef)
    $c->authz->dynamic_attrs($resource, $action, $coderef)

Registers a dynamic attributes callback function. `$coderef` must be a CODEREF
or undefined. Dynamic attrs functions are searched from most to least specific,
so a general function may be overridden with a more-specific one, or blocked
entirely with an undefined entry, e.g.,

    $c->authz->dynamic_attrs(Book => sub($c, $ctx) { ... } );
    $c->authz->dynamic_attrs(Book => list => undef);

The first line declares a handler for attributes of Book resources. The second
clears the handler for the list action of Book resources, so the handler is used
for all Book resources, except for list actions.

# AUTHOR

Mark Tyrrell `<mark@tyrrminal.dev>`

# LICENSE

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
