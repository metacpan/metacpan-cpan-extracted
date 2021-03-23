package Mojolicious::Plugin::DBIC::Controller::DBIC;
our $VERSION = '0.004';
# ABSTRACT: Build simple views to DBIC data

#pod =head1 SYNOPSIS
#pod
#pod     use Mojolicious::Lite;
#pod     plugin DBIC => { schema => ... };
#pod     get '/', {
#pod         controller => 'DBIC',
#pod         action => 'list',
#pod         resultset => 'BlogPosts',
#pod         template => 'blog/list',
#pod     };
#pod
#pod =head1 DESCRIPTION
#pod
#pod This controller allows for easy working with data from the schema.
#pod Controllers are configured through the stash when setting up the routes.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Mojolicious::Plugin::DBIC>
#pod
#pod =cut

use Mojo::Base 'Mojolicious::Controller';

#pod =method list
#pod
#pod     get '/', {
#pod         controller => 'DBIC',
#pod         action => 'list',
#pod         resultset => 'BlogPosts',
#pod         template => 'blog/list',
#pod     };
#pod
#pod List data in a ResultSet. Returns false if it has rendered a response,
#pod true if dispatch can continue.
#pod
#pod This method uses the following stash values for configuration:
#pod
#pod =over
#pod
#pod =item resultset
#pod
#pod The L<DBIx::Class::ResultSet> class to list.
#pod
#pod =back
#pod
#pod This method sets the following stash values for template rendering:
#pod
#pod =over
#pod
#pod =item resultset
#pod
#pod The L<DBIx::Class::ResultSet> object containing the desired objects.
#pod
#pod =back
#pod
#pod =cut

sub list {
    my ( $c ) = @_;
    my $rs_class = $c->stash( 'resultset' );
    my $rs = $c->schema->resultset( $rs_class );
    return $c->stash(
        resultset => $rs,
    );
}

#pod =method get
#pod
#pod     get '/blog/:id', {
#pod         controller => 'DBIC',
#pod         action => 'get',
#pod         resultset => 'BlogPosts',
#pod         template => 'blog/get',
#pod     };
#pod
#pod Fetch a single result by its ID. If no result is found, renders a not
#pod found error. Returns false if it has rendered a response, true if
#pod dispatch can continue.
#pod
#pod This method uses the following stash values for configuration:
#pod
#pod =over
#pod
#pod =item resultset
#pod
#pod The L<DBIx::Class::ResultSet> class to use.
#pod
#pod =item id
#pod
#pod The ID to pass to L<DBIx::Class::ResultSet/find>.
#pod
#pod =back
#pod
#pod This method sets the following stash values for template rendering:
#pod
#pod =over
#pod
#pod =item row
#pod
#pod The L<DBIx::Class::Row> object containing the desired object.
#pod
#pod =back
#pod
#pod =cut

sub get {
    my ( $c ) = @_;
    my $rs_class = $c->stash( 'resultset' );
    my $id = $c->stash( 'id' );
    my $rs = $c->schema->resultset( $rs_class );
    my $row = $rs->find( $id );
    if ( !$row ) {
        $c->reply->not_found;
        return;
    }
    return $c->stash(
        row => $row,
    );
}

#pod =method set
#pod
#pod     $routes->any( [ 'GET', 'POST' ] => '/:id/edit' )->to(
#pod         'DBIC#set',
#pod         resultset => $resultset_name,
#pod         template => $template_name,
#pod     );
#pod
#pod     $routes->any( [ 'GET', 'POST' ] => '/create' )->to(
#pod         'DBIC#set',
#pod         resultset => $resultset_name,
#pod         template => $template_name,
#pod         forward_to => $route_name,
#pod     );
#pod
#pod This route creates a new item or updates an existing item in
#pod a collection. If the user is making a C<GET> request, they will simply
#pod be shown the template. If the user is making a C<POST> or C<PUT>
#pod request, the form parameters will be read, and the user will either be
#pod shown the form again with the result of the form submission (success or
#pod failure) or the user will be forwarded to another place.
#pod
#pod This method uses the following stash values for configuration:
#pod
#pod =over
#pod
#pod =item resultset
#pod
#pod The resultset to use. Required.
#pod
#pod =item id
#pod
#pod The ID of the item from the collection. Optional: If not specified, a new
#pod item will be created. Usually part of the route path as a placeholder.
#pod
#pod =item template
#pod
#pod The name of the template to use. See L<Mojolicious::Guides::Rendering/Renderer>
#pod for how template names are resolved.
#pod
#pod =item forward_to
#pod
#pod The name of a route to forward the user to on success. Optional. Any
#pod route placeholders that match item field names will be filled in.
#pod
#pod     $routes->get( '/:id/:slug' )->name( 'blog.view' );
#pod     $routes->post( '/create' )->to(
#pod         'DBIC#set',
#pod         resultset => 'blog',
#pod         template => 'blog_edit.html.ep',
#pod         forward_to => 'blog.view',
#pod     );
#pod
#pod     # { id => 1, slug => 'first-post' }
#pod     # forward_to => '/1/first-post'
#pod
#pod Forwarding will not happen for JSON requests.
#pod
#pod =item properties
#pod
#pod Restrict this route to only setting the given properties. An array
#pod reference of properties to allow. Trying to set additional properties
#pod will result in an error.
#pod
#pod B<NOTE:> Unless restricted to certain properties using this
#pod configuration, this method accepts all valid data configured for the
#pod collection. The data being submitted can be more than just the fields
#pod you make available in the form. If you do not want certain data to be
#pod written through this form, you can prevent it by using this.
#pod
#pod =back
#pod
#pod The following stash values are set by this method:
#pod
#pod =over
#pod
#pod =item row
#pod
#pod The L<DBIx::Class::Row> that is being edited, if the C<id> is given.
#pod Otherwise, the item that was created.
#pod
#pod =item error
#pod
#pod A scalar containing the exception thrown by the insert/update.
#pod
#pod =back
#pod
#pod Each field in the item is also set as a param using
#pod L<Mojolicious::Controller/param> so that tag helpers like C<text_field>
#pod will be pre-filled with the values. See
#pod L<Mojolicious::Plugin::TagHelpers> for more information. This also means
#pod that fields can be pre-filled with initial data or new data by using GET
#pod query parameters.
#pod
#pod This method is protected by L<Mojolicious's Cross-Site Request Forgery
#pod (CSRF) protection|Mojolicious::Guides::Rendering/Cross-site request
#pod forgery>. CSRF protection prevents other sites from tricking your users
#pod into doing something on your site that they didn't intend, such as
#pod editing or deleting content. You must add a C<< <%= csrf_field %> >> to
#pod your form in order to delete an item successfully. See
#pod L<Mojolicious::Guides::Rendering/Cross-site request forgery>.
#pod
#pod Displaying a form could be done as a separate route using the C<dbic#get>
#pod method, but with more code:
#pod
#pod     $routes->get( '/:id/edit' )->to(
#pod         'DBIC#get',
#pod         resultset => $resultset_name,
#pod         template => $template_name,
#pod     );
#pod     $routes->post( '/:id/edit' )->to(
#pod         'DBIC#set',
#pod         resultset => $resultset_name,
#pod         template => $template_name,
#pod     );
#pod
#pod =cut

sub set {
    my ( $c ) = @_;
    my $rs_class = $c->stash( 'resultset' )
        || die q{"resultset" name not defined in stash};
    my $id = $c->stash( 'id' );

    # Display the form, if requested. This makes the simple case of
    # displaying and managing a form easier with a single route instead
    # of two routes (one to "yancy#get" and one to "yancy#set")
    if ( $c->req->method eq 'GET' ) {
        if ( $id ) {
            my $row = $c->schema->resultset( $rs_class )->find( $id );
            $c->stash( row => $row );
            my @props = $row->result_source->columns;
            for my $key ( @props ) {
                # Mojolicious TagHelpers take current values through the
                # params, but also we allow pre-filling values through the
                # GET query parameters (except for passwords)
                $c->param( $key => $c->param( $key ) // $row->$key );
            }
        }

        $c->respond_to(
            json => {
                status => 400,
                json => {
                    errors => [
                        {
                            message => 'GET request for JSON invalid',
                        },
                    ],
                },
            },
            html => { },
        );
        return;
    }

    if ( $c->accepts( 'html' ) && $c->validation->csrf_protect->has_error( 'csrf_token' ) ) {
        $c->app->log->error( 'CSRF token validation failed' );
        $c->render(
            status => 400,
            row => $id ? $c->schema->resultset( $rs_class )->find( $id ) : undef,
            errors => [
                {
                    message => 'CSRF token invalid.',
                },
            ],
        );
        return;
    }

    my $data = $c->req->params->to_hash;
    delete $data->{csrf_token};
    #; use Data::Dumper;
    #; $c->app->log->debug( Dumper $data );

    my $rs = $c->schema->resultset( $rs_class );
    if ( my $props = $c->stash( 'properties' ) ) {
        $data = {
            map { $_ => $data->{ $_ } }
            grep { exists $data->{ $_ } }
            @$props
        };
    }

    my $row;
    my $update = $id ? 1 : 0;
    if ( $update ) {
        $row = $rs->find( $id );
        eval { $row->update( $data ) };
    }
    else {
        $row = eval { $rs->create( $data ) };
    }

    if ( my $error = $@ ) {
        $c->app->log->error( 'Error in set: ' . $error );
        $c->res->code( 500 );
        $row = $id ? $rs->find( $id ) : undef;
        $c->respond_to(
            json => { json => { error => $error } },
            html => { row => $row, error => $error },
        );
        return;
    }

    return $c->respond_to(
        json => sub {
            $c->stash(
                status => $update ? 200 : 201,
                json => $row->get_inflated_columns,
            );
        },
        html => sub {
            if ( my $route = $c->stash( 'forward_to' ) ) {
                $c->redirect_to( $route, $row->get_inflated_columns );
                return;
            }
            $c->stash( row => $row );
        },
    );
}

#pod =method delete
#pod
#pod     $routes->any( [ 'GET', 'POST' ], '/delete/:id' )->to(
#pod         'DBIC#delete',
#pod         resultset => $resultset_name,
#pod         template => $template_name,
#pod         forward_to => $route_name,
#pod     );
#pod
#pod This route deletes a row from a ResultSet. If the user is making
#pod a C<GET> request, they will simply be shown the template (which can be
#pod used to confirm the delete). If the user is making a C<POST> or C<DELETE>
#pod request, the row will be deleted and the user will either be shown the
#pod form again with the result of the form submission (success or failure)
#pod or the user will be forwarded to another place.
#pod
#pod This method uses the following stash values for configuration:
#pod
#pod =over
#pod
#pod =item resultset
#pod
#pod The ResultSet class to use. Required.
#pod
#pod =item id
#pod
#pod The ID of the row from the table. Required. Usually part of the
#pod route path as a placeholder.
#pod
#pod =item template
#pod
#pod The name of the template to use. See L<Mojolicious::Guides::Rendering/Renderer>
#pod for how template names are resolved.
#pod
#pod =item forward_to
#pod
#pod The name of a route to forward the user to on success. Optional.
#pod Forwarding will not happen for JSON requests.
#pod
#pod =back
#pod
#pod The following stash values are set by this method:
#pod
#pod =over
#pod
#pod =item row
#pod
#pod The row that will be deleted. If displaying the form again after the row
#pod is deleted, this will be C<undef>.
#pod
#pod =back
#pod
#pod This method is protected by L<Mojolicious's Cross-Site Request Forgery
#pod (CSRF) protection|Mojolicious::Guides::Rendering/Cross-site request
#pod forgery>. CSRF protection prevents other sites from tricking your users
#pod into doing something on your site that they didn't intend, such as
#pod editing or deleting content. You must add a C<< <%= csrf_field %> >> to
#pod your form in order to delete an item successfully. See
#pod L<Mojolicious::Guides::Rendering/Cross-site request forgery>.
#pod
#pod =cut

sub delete {
    my ( $c ) = @_;
    my $rs_class = $c->stash( 'resultset' );
    my $id = $c->stash( 'id' );
    my $rs = $c->schema->resultset( $rs_class );
    my $row = $rs->find( $id );

    # Display the form, if requested. This makes it easy to display
    # a confirmation page in a single route.
    if ( $c->req->method eq 'GET' ) {
        $c->respond_to(
            json => {
                status => 400,
                json => {
                    errors => [
                        {
                            message => 'GET request for JSON invalid',
                        },
                    ],
                },
            },
            html => { row => $row },
        );
        return;
    }

    if ( $c->accepts( 'html' ) && $c->validation->csrf_protect->has_error( 'csrf_token' ) ) {
        $c->app->log->error( 'CSRF token validation failed' );
        $c->render(
            status => 400,
            row => $row,
            errors => [
                {
                    message => 'CSRF token invalid.',
                },
            ],
        );
        return;
    }

    $row->delete;

    return $c->respond_to(
        json => sub {
            $c->rendered( 204 );
            return;
        },
        html => sub {
            if ( my $route = $c->stash( 'forward_to' ) ) {
                $c->redirect_to( $route );
                return;
            }
        },
    );
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Mojolicious::Plugin::DBIC::Controller::DBIC - Build simple views to DBIC data

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    use Mojolicious::Lite;
    plugin DBIC => { schema => ... };
    get '/', {
        controller => 'DBIC',
        action => 'list',
        resultset => 'BlogPosts',
        template => 'blog/list',
    };

=head1 DESCRIPTION

This controller allows for easy working with data from the schema.
Controllers are configured through the stash when setting up the routes.

=head1 METHODS

=head2 list

    get '/', {
        controller => 'DBIC',
        action => 'list',
        resultset => 'BlogPosts',
        template => 'blog/list',
    };

List data in a ResultSet. Returns false if it has rendered a response,
true if dispatch can continue.

This method uses the following stash values for configuration:

=over

=item resultset

The L<DBIx::Class::ResultSet> class to list.

=back

This method sets the following stash values for template rendering:

=over

=item resultset

The L<DBIx::Class::ResultSet> object containing the desired objects.

=back

=head2 get

    get '/blog/:id', {
        controller => 'DBIC',
        action => 'get',
        resultset => 'BlogPosts',
        template => 'blog/get',
    };

Fetch a single result by its ID. If no result is found, renders a not
found error. Returns false if it has rendered a response, true if
dispatch can continue.

This method uses the following stash values for configuration:

=over

=item resultset

The L<DBIx::Class::ResultSet> class to use.

=item id

The ID to pass to L<DBIx::Class::ResultSet/find>.

=back

This method sets the following stash values for template rendering:

=over

=item row

The L<DBIx::Class::Row> object containing the desired object.

=back

=head2 set

    $routes->any( [ 'GET', 'POST' ] => '/:id/edit' )->to(
        'DBIC#set',
        resultset => $resultset_name,
        template => $template_name,
    );

    $routes->any( [ 'GET', 'POST' ] => '/create' )->to(
        'DBIC#set',
        resultset => $resultset_name,
        template => $template_name,
        forward_to => $route_name,
    );

This route creates a new item or updates an existing item in
a collection. If the user is making a C<GET> request, they will simply
be shown the template. If the user is making a C<POST> or C<PUT>
request, the form parameters will be read, and the user will either be
shown the form again with the result of the form submission (success or
failure) or the user will be forwarded to another place.

This method uses the following stash values for configuration:

=over

=item resultset

The resultset to use. Required.

=item id

The ID of the item from the collection. Optional: If not specified, a new
item will be created. Usually part of the route path as a placeholder.

=item template

The name of the template to use. See L<Mojolicious::Guides::Rendering/Renderer>
for how template names are resolved.

=item forward_to

The name of a route to forward the user to on success. Optional. Any
route placeholders that match item field names will be filled in.

    $routes->get( '/:id/:slug' )->name( 'blog.view' );
    $routes->post( '/create' )->to(
        'DBIC#set',
        resultset => 'blog',
        template => 'blog_edit.html.ep',
        forward_to => 'blog.view',
    );

    # { id => 1, slug => 'first-post' }
    # forward_to => '/1/first-post'

Forwarding will not happen for JSON requests.

=item properties

Restrict this route to only setting the given properties. An array
reference of properties to allow. Trying to set additional properties
will result in an error.

B<NOTE:> Unless restricted to certain properties using this
configuration, this method accepts all valid data configured for the
collection. The data being submitted can be more than just the fields
you make available in the form. If you do not want certain data to be
written through this form, you can prevent it by using this.

=back

The following stash values are set by this method:

=over

=item row

The L<DBIx::Class::Row> that is being edited, if the C<id> is given.
Otherwise, the item that was created.

=item error

A scalar containing the exception thrown by the insert/update.

=back

Each field in the item is also set as a param using
L<Mojolicious::Controller/param> so that tag helpers like C<text_field>
will be pre-filled with the values. See
L<Mojolicious::Plugin::TagHelpers> for more information. This also means
that fields can be pre-filled with initial data or new data by using GET
query parameters.

This method is protected by L<Mojolicious's Cross-Site Request Forgery
(CSRF) protection|Mojolicious::Guides::Rendering/Cross-site request
forgery>. CSRF protection prevents other sites from tricking your users
into doing something on your site that they didn't intend, such as
editing or deleting content. You must add a C<< <%= csrf_field %> >> to
your form in order to delete an item successfully. See
L<Mojolicious::Guides::Rendering/Cross-site request forgery>.

Displaying a form could be done as a separate route using the C<dbic#get>
method, but with more code:

    $routes->get( '/:id/edit' )->to(
        'DBIC#get',
        resultset => $resultset_name,
        template => $template_name,
    );
    $routes->post( '/:id/edit' )->to(
        'DBIC#set',
        resultset => $resultset_name,
        template => $template_name,
    );

=head2 delete

    $routes->any( [ 'GET', 'POST' ], '/delete/:id' )->to(
        'DBIC#delete',
        resultset => $resultset_name,
        template => $template_name,
        forward_to => $route_name,
    );

This route deletes a row from a ResultSet. If the user is making
a C<GET> request, they will simply be shown the template (which can be
used to confirm the delete). If the user is making a C<POST> or C<DELETE>
request, the row will be deleted and the user will either be shown the
form again with the result of the form submission (success or failure)
or the user will be forwarded to another place.

This method uses the following stash values for configuration:

=over

=item resultset

The ResultSet class to use. Required.

=item id

The ID of the row from the table. Required. Usually part of the
route path as a placeholder.

=item template

The name of the template to use. See L<Mojolicious::Guides::Rendering/Renderer>
for how template names are resolved.

=item forward_to

The name of a route to forward the user to on success. Optional.
Forwarding will not happen for JSON requests.

=back

The following stash values are set by this method:

=over

=item row

The row that will be deleted. If displaying the form again after the row
is deleted, this will be C<undef>.

=back

This method is protected by L<Mojolicious's Cross-Site Request Forgery
(CSRF) protection|Mojolicious::Guides::Rendering/Cross-site request
forgery>. CSRF protection prevents other sites from tricking your users
into doing something on your site that they didn't intend, such as
editing or deleting content. You must add a C<< <%= csrf_field %> >> to
your form in order to delete an item successfully. See
L<Mojolicious::Guides::Rendering/Cross-site request forgery>.

=head1 SEE ALSO

L<Mojolicious::Plugin::DBIC>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
