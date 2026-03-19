use v5.36;
package PlackX::Framework::Role::RouterEngine {
  use Role::Tiny;
  requires qw(new instance match add_route add_global_filter freeze);
}

1;

=pod

=head1 NAME

PlackX::Framework::Role::RouterEngine


=head1 SYNOPSIS

    package My::Router::Engine {
        use Role::Tiny::With;
        with 'PlackX::Framework::Role::RouterEngine';
        sub new       { ... }
        sub instance  { ... }
        sub match     { ... }
        sub add_route { ... }
        sub add_global_filter { ... }
    }


=head1 DESCRIPTION

This module defines a role which can be used to create a custom Router::Engine
class for PlackX::Framework.

The Engine class shall be a singleton which returns one object instance per
subclass.


=head1 REQUIRED CLASS METHODS

=over 4

=item new, instance

Return an instance of the class.

=back

=head1 REQUIRED OBJECT METHODS

=over 4

=item $engine->match($request)

Use a PlackX::Framework::Request object to find a matching route. The return
value shall be undef or false if no match is found. If a match is found, a
hashref should be returned. The hashref should contain the following keys:

=item route_parameters

A hashref of route parameters that were collected during the route match. If
no parameters are applicable, it should be an empty hashref (not undef).

=item action

The subref to be called by PlackX::Framework::Handler to execute the route.

=item prefilters, postfilters

An arrayref of subrefs to be executed before or after the main action, to
include both local (package-scoped) and global filters. Filtes should be
in the same order in which they were added, except that global prefilters
should come before local prefilters, and global postfilters should come
after local postfilters.

=item $engine->add_route(...)

Add a route. Accepted parameters should be a list of key-value pairs with the
following keys:

=over 4

=item spec

A route specification, which can be a string path, arrayref of paths, or a
hashref with a verb (HTTP request method) as the key(s) and the previously
described string or arrayref as the value(s). The engine should allow regex
matching and parameterization of path elements, as described in the default
engine base class for PlackX::Framework, Router::Boom.

=item base

An optional base uri path to be used as a prefix for the spec path uri(s).

(A future version might eliminate this parameter, such that the Router.pm
package handles it before sending it to the engine.)

=item prefilters

An arrayref of local (package-scoped) prefilters.

=item postfilters

An arrayref of local (package-scoped) postfilters.

=back

=item $obj->add_global_filter(...)

Add a global filter. Parameters should be a list of key-value pairs with the following
keys:

=over 4

=item when

The string "before" or "after" for prefilters and postfilters, respectively.

=item action

A subref to be executed.

=item pattern

An optional path segment or pattern such that the filter will only apply if the
request path matches the pattern.

The pattern may be one of:

1. a string, in which case the global filter should match if the request
path_info STARTS WITH the string.

2. a scalar reference to the string, in which case the global filter should
match if the request path_info is identical to the string.

3. a reference to a regex, in which case the global filter should match if
the request path_info =~ the regex.

=back

=item $obj->freeze

A method telling the router engine to compile itself and prevent more routes
from being added. This is required but may be implemented as a no-op.

=back

=head1 META

For copyright and license, see PlackX::Framework.

