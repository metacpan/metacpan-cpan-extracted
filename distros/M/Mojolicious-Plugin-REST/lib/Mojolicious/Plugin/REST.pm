package Mojolicious::Plugin::REST;

# ABSTRACT: Mojolicious Plugin for RESTful operations
our $VERSION = '0.006'; # VERSION
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Exception;
use Lingua::EN::Inflect 1.895 qw/PL/;

my $http2crud = {
    collection => {
        get  => 'list',
        post => 'create',
    },
    resource => {
        get    => 'read',
        put    => 'update',
        delete => 'delete'
    },
};

has install_hook => 1;

sub register {
    my $self    = shift;
    my $app     = shift;
    my $options = { @_ ? ( ref $_[0] ? %{ $_[0] } : @_ ) : () };

    # prefix, version, stuff...
    my $url_prefix = '';
    foreach my $modifier (qw(prefix version)) {
        if ( defined $options->{$modifier} && $options->{$modifier} ne '' ) {
            $url_prefix .= "/" . $options->{$modifier};
        }
    }

    # method name for bridged actions...
    my $method_chained = $options->{method_chained} // 'chained';

    # override default http2crud mapping from options...
    if ( exists( $options->{http2crud} ) ) {
        foreach my $method_type ( keys( %{$http2crud} ) ) {
            next unless exists $options->{http2crud}->{$method_type};
            foreach my $method ( keys( %{ $http2crud->{$method_type} } ) ) {
                next unless exists $options->{http2crud}->{$method_type}->{$method};
                $http2crud->{$method_type}->{$method} = $options->{http2crud}->{$method_type}->{$method};
            }
        }
    }

    # install app hook if not disabled...
    $self->install_hook(0) if ( defined( $options->{hook} ) and $options->{hook} == 0 );
    if ( $self->install_hook ) {
        $app->hook(
            before_render => sub {
                my $c = shift;
                my $path_substr = substr "" . $c->req->url->path, 0, length $url_prefix;
                if ( $path_substr eq $url_prefix ) {
                    my $json = $c->stash('json');
                    unless ( defined $json->{data} ) {
                        $json->{data} = {};
                        $c->stash( 'json' => $json );
                    }
                }
            }
        );
    }

    $app->routes->add_shortcut(
        rest_routes => sub {

            my $routes = shift;

            my $params = { @_ ? ( ref $_[0] ? %{ $_[0] } : @_ ) : () };

            Mojo::Exception->throw('Route name is required in rest_routes') unless defined $params->{name};

            # name setting
            my $route_name = $params->{name};
            my ( $route_name_lower, $route_name_plural, $route_id );
            $route_name_lower  = lc $route_name;
            $route_name_plural = PL( $route_name_lower, 10 );
            $route_id          = ":" . $route_name_lower . "Id";

            # under setting
            my $under_name = $params->{under};
            my ( $under_name_lower, $under_name_plural, $under_id );
            if ( defined($under_name) and $under_name ne '' ) {
                $under_name_lower  = lc $under_name;
                $under_name_plural = PL( $under_name_lower, 10 );
                $under_id          = ":" . $under_name_lower . "Id";
            }

            # controller
            my $controller = $params->{controller} // ucfirst($route_name_lower);

            foreach my $collection_method ( sort keys( %{ $http2crud->{collection} } ) ) {
                next
                    if ( defined $params->{methods}
                    && index( $params->{methods}, substr( $http2crud->{collection}->{$collection_method}, 0, 1 ) )
                    == -1 );

                my $url           = "/$route_name_plural";
                my $action_suffix = "_" . $route_name_lower;
                if ( defined($under_name) ) {
                    $url           = "/$under_name_plural/$under_id" . $url;
                    $action_suffix = "_" . $under_name_lower . $action_suffix;
                }

                $url = $url_prefix . $url;
                my $action = $http2crud->{collection}->{$collection_method} . $action_suffix;

                if ( defined($under_name) ) {
                    my $bridge_controller = ucfirst($under_name_lower);
                    my $bridge
                        = $routes->bridge($url)->to( controller => $bridge_controller, action => $method_chained )
                        ->name("${bridge_controller}::${method_chained}()")
                        ->route->via($collection_method)->to( controller => $controller, action => $action )
                        ->name("${controller}::${action}()");
                }
                else {
                    $routes->route($url)->via($collection_method)->to( controller => $controller, action => $action )
                        ->name("${controller}::${action}()");

                }

            }
            foreach my $resource_method ( sort keys( %{ $http2crud->{resource} } ) ) {
                next
                    if ( defined $params->{methods}
                    && index( $params->{methods}, substr( $http2crud->{resource}->{$resource_method}, 0, 1 ) ) == -1 );

                my $ids = [];

                if ( defined( $params->{types} ) ) {
                    $ids = $params->{types};
                }
                else {
                    push @$ids, $route_id;
                }

                foreach my $id (@$ids) {
                    if ( defined( $params->{types} ) ) {
                        $controller = $params->{controller} // ucfirst($route_name_lower);
                        $controller .= '::' . ucfirst($id);
                    }

                    my $url           = "/$route_name_plural/$id";
                    my $action_suffix = "_" . $route_name_lower;
                    if ( defined($under_name) ) {
                        $url           = "/$under_name_plural/$under_id" . $url;
                        $action_suffix = "_" . $under_name_lower . $action_suffix;
                    }
                    $url = $url_prefix . $url;
                    my $action = $http2crud->{resource}->{$resource_method} . $action_suffix;

                    if ( defined($under_name) ) {
                        my $bridge_controller = ucfirst($under_name_lower);
                        my $bridge
                            = $routes->bridge($url)->to( controller => $bridge_controller, action => $method_chained )
                            ->name("${bridge_controller}::${method_chained}()")
                            ->route->via($resource_method)->to( controller => $controller, action => $action )
                            ->name("${controller}::${action}()");

                    }
                    else {
                        $routes->route($url)->via($resource_method)->to( controller => $controller, action => $action )
                            ->name("${controller}::${action}()");
                    }

                }

            }

        }
    );

}

1;

__END__

=pod

=head1 NAME

Mojolicious::Plugin::REST - Mojolicious Plugin for RESTful operations

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    # In Mojolicious Application
    $self->plugin( 'REST' => { prefix => 'api', version => 'v1' } );

    $routes->rest_routes( name => 'Account' );

    # Installs following routes:

    # /api/v1/accounts             ....  GET     "Account::list_account()"    ^/api/v1/accounts(?:\.([^/]+)$)?
    # /api/v1/accounts             ....  POST    "Account::create_account()"  ^/api/v1/accounts(?:\.([^/]+)$)?
    # /api/v1/accounts/:accountId  ....  DELETE  "Account::delete_account()"  ^/api/v1/accounts/([^\/\.]+)(?:\.([^/]+)$)?
    # /api/v1/accounts/:accountId  ....  GET     "Account::read_account()"    ^/api/v1/accounts/([^\/\.]+)(?:\.([^/]+)$)?
    # /api/v1/accounts/:accountId  ....  PUT     "Account::update_account()"  ^/api/v1/accounts/([^\/\.]+)(?:\.([^/]+)$)?


    $routes->rest_routes( name => 'Feature', under => 'Account' );

    # Installs following routes:

    # /api/v1/accounts/:accountId/features             B...  *       "Account::chained()"                 ^/api/v1/accounts/([^\/\.]+)/features
    #   +/                                             ....  GET     "Feature::list_account_feature()"    ^(?:\.([^/]+)$)?
    # /api/v1/accounts/:accountId/features             B...  *       "Account::chained()"                 ^/api/v1/accounts/([^\/\.]+)/features
    #   +/                                             ....  POST    "Feature::create_account_feature()"  ^(?:\.([^/]+)$)?
    # /api/v1/accounts/:accountId/features/:featureId  B...  *       "Account::chained()"                 ^/api/v1/accounts/([^\/\.]+)/features/([^\/\.]+)
    #   +/                                             ....  DELETE  "Feature::delete_account_feature()"  ^(?:\.([^/]+)$)?
    # /api/v1/accounts/:accountId/features/:featureId  B...  *       "Account::chained()"                 ^/api/v1/accounts/([^\/\.]+)/features/([^\/\.]+)
    #   +/                                             ....  GET     "Feature::read_account_feature()"    ^(?:\.([^/]+)$)?
    # /api/v1/accounts/:accountId/features/:featureId  B...  *       "Account::chained()"                 ^/api/v1/accounts/([^\/\.]+)/features/([^\/\.]+)
    #   +/                                             ....  PUT     "Feature::update_account_feature()"  ^(?:\.([^/]+)$)?


    $routes->rest_routes( name => 'Product', under => 'Account', types => [qw(ftp ssh)] );

    # Installs following routes:

    # /api/v1/accounts/:accountId/products      B...  *       "Account::chained()"                      ^/api/v1/accounts/([^\/\.]+)/products
    #   +/                                      ....  GET     "Product::list_account_product()"         ^(?:\.([^/]+)$)?
    # /api/v1/accounts/:accountId/products      B...  *       "Account::chained()"                      ^/api/v1/accounts/([^\/\.]+)/products
    #   +/                                      ....  POST    "Product::create_account_product()"       ^(?:\.([^/]+)$)?
    # /api/v1/accounts/:accountId/products/ftp  B...  *       "Account::chained()"                      ^/api/v1/accounts/([^\/\.]+)/products/ftp
    #   +/                                      ....  DELETE  "Product::Ftp::delete_account_product()"  ^(?:\.([^/]+)$)?
    # /api/v1/accounts/:accountId/products/ssh  B...  *       "Account::chained()"                      ^/api/v1/accounts/([^\/\.]+)/products/ssh
    #   +/                                      ....  DELETE  "Product::Ssh::delete_account_product()"  ^(?:\.([^/]+)$)?
    # /api/v1/accounts/:accountId/products/ftp  B...  *       "Account::chained()"                      ^/api/v1/accounts/([^\/\.]+)/products/ftp
    #   +/                                      ....  GET     "Product::Ftp::read_account_product()"    ^(?:\.([^/]+)$)?
    # /api/v1/accounts/:accountId/products/ssh  B...  *       "Account::chained()"                      ^/api/v1/accounts/([^\/\.]+)/products/ssh
    #   +/                                      ....  GET     "Product::Ssh::read_account_product()"    ^(?:\.([^/]+)$)?
    # /api/v1/accounts/:accountId/products/ftp  B...  *       "Account::chained()"                      ^/api/v1/accounts/([^\/\.]+)/products/ftp
    #   +/                                      ....  PUT     "Product::Ftp::update_account_product()"  ^(?:\.([^/]+)$)?
    # /api/v1/accounts/:accountId/products/ssh  B...  *       "Account::chained()"                      ^/api/v1/accounts/([^\/\.]+)/products/ssh
    #   +/                                      ....  PUT     "Product::Ssh::update_account_product()"  ^(?:\.([^/]+)$)?

=head1 DESCRIPTION

L<Mojolicious::Plugin::REST> adds various helpers for L<REST|http://en.wikipedia.org/wiki/Representational_state_transfer>ful
L<CRUD|http://en.wikipedia.org/wiki/Create,_read,_update_and_delete> operations via
L<HTTP|http://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol> to your mojolicious application.

As much as possible, it tries to follow L<RESTful API Design|https://blog.apigee.com/detail/restful_api_design> principles from Apigee.

Used in conjuction with L<Mojolicious::Controller::REST>, this module makes building RESTful application a breeze.

This module is inspired from L<Mojolicious::Plugin::RESTRoutes>.

=head1 WARNING

This module is still under development, and it's possible that things may change between releases without warning or deprecations.

=head1 MOJOLICIOUS HELPERS

=head2 rest_routes

A routes shortcut to easily add RESTful routes for a resource and associations.

=head1 MOJOLICIOUS HOOKS

This module installs an before_render application hook, which gurantees JSON output.

Refer L<Mojolicious::Controller::REST> documentation for output format.

Hook installation can be disabled by passing hook => 0 in plugin options. For Example:

    $self->plugin( 'REST', prefix => 'api', version => 'v1', hook => 0 );

=head1 OPTIONS

Following options can be used to control route creation:

=over

=item methods

This option can be used to control which methods are created for declared rest_route. Each character in the value of this option,
determined if corresponding route will be created or ommited. For Example:

    $routes->rest_routes( name => 'Account', methods => 'crudl' );

This will install all the rest routes, value 'crudl' signifies:

    c - create
    r - read
    u - update
    d - delete
    l - list.

Only methods whose first character is mentioned in the value for this option will be created. For Example:

    $routes->rest_routes( name => 'Account', methods => 'crd' );

This will install only create, read and delete routes as below:

    # /api/v1/accounts             ....  POST    "Account::create_account()"  ^/api/v1/accounts(?:\.([^/]+)$)?
    # /api/v1/accounts/:accountId  ....  DELETE  "Account::delete_account()"  ^/api/v1/accounts/([^\/\.]+)(?:\.([^/]+)$)?
    # /api/v1/accounts/:accountId  ....  GET     "Account::read_account()"    ^/api/v1/accounts/([^\/\.]+)(?:\.([^/]+)$)?

option value 'crd' signifies,
    c - create,
    r - read,
    d - delete

Old B<readonly> behaviour can thus be achieved using:

    $routes->rest_routes( name => 'Account', methods => 'cl' );

This will install only create and list routes as below:

    # /api/v1/accounts  ....  GET   "Account::list_account()"    ^/api/v1/accounts(?:\.([^/]+)$)?
    # /api/v1/accounts  ....  POST  "Account::create_account()"  ^/api/v1/accounts(?:\.([^/]+)$)?

=item name

The name of the resource, e.g. 'User'. This name will be used to build the route url as well as the controller name.

=item controller

By default, resource name will be converted to CamelCase controller name. You can change it by providing controller name.

If customized, this options needs a full namespace of the controller class.

=item under

This option can be used for associations. If present, url's for named resource will be created under given under resource. The actions created,
will be bridged under 'method_chained' method of given under resouce. For Example:

    $routes->rest_routes( name => 'Feature', under => 'Account' );

    # will create following routes, where routes for feature are bridged under Account::chained()

    # /api/v1/accounts/:accountId/features             B...  *       "Account::chained()"                 ^/api/v1/accounts/([^\/\.]+)/features
    #   +/                                             ....  GET     "Feature::list_account_feature()"    ^(?:\.([^/]+)$)?
    # /api/v1/accounts/:accountId/features             B...  *       "Account::chained()"                 ^/api/v1/accounts/([^\/\.]+)/features
    #   +/                                             ....  POST    "Feature::create_account_feature()"  ^(?:\.([^/]+)$)?
    # /api/v1/accounts/:accountId/features/:featureId  B...  *       "Account::chained()"                 ^/api/v1/accounts/([^\/\.]+)/features/([^\/\.]+)
    #   +/                                             ....  DELETE  "Feature::delete_account_feature()"  ^(?:\.([^/]+)$)?
    # /api/v1/accounts/:accountId/features/:featureId  B...  *       "Account::chained()"                 ^/api/v1/accounts/([^\/\.]+)/features/([^\/\.]+)
    #   +/                                             ....  GET     "Feature::read_account_feature()"    ^(?:\.([^/]+)$)?
    # /api/v1/accounts/:accountId/features/:featureId  B...  *       "Account::chained()"                 ^/api/v1/accounts/([^\/\.]+)/features/([^\/\.]+)
    #   +/                                             ....  PUT     "Feature::update_account_feature()"  ^(?:\.([^/]+)$)?

Note that, The actual bridge code needs to return a true value or the dispatch chain will be broken. Please refer
L<Mojolicious Bridges Documentation|https://metacpan.org/pod/Mojolicious::Guides::Routing#Bridges> for more information on bridges in Mojolicious.

=item types

This option can be used to specify types of resources available in application.

=back

=head1 PLUGIN OPTIONS

=over

=item method_chained

If present, this value will be used as a method name for chained methods in route bridges.

=item prefix

If present, this value will be added as prefix to all routes created.

=item version

If present, this value will be added as prefix to all routes created but after prefix.

=item htt2crud

If present, given HTTP to CRUD mapping will be used to determine method names. Default mapping:

    {
        collection => {
            get  => 'list',
            post => 'create',
        },

        resource => {
            get    => 'read',
            put    => 'update',
            delete => 'delete'
        }
    }

=back

=head1 AUTHOR

Abhishek Shende <abhishekisnot@gmail.com>

=head1 CONTRIBUTOR

Vincent HETRU <vincent.hetru@13pass.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Abhishek Shende.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
