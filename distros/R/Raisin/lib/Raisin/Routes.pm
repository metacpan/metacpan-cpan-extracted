#!perl
#PODNAME: Raisin::Routes
#ABSTRACT: A routing class for Raisin.

use strict;
use warnings;

package Raisin::Routes;
$Raisin::Routes::VERSION = '0.94';
use Carp;
use Plack::Util::Accessor qw(
    cache
    list
    routes
);

use Raisin::Param;
use Raisin::Routes::Endpoint;
use Raisin::Util;

sub new {
    my $class = shift;
    my $self = bless { id => rand() }, $class;

    $self->cache({});
    $self->list({});
    $self->routes([]);

    $self;
}

sub add {
    my ($self, %params) = @_;

    my $method = uc $params{method};
    my $path = $params{path};

    if (!$method || !$path) {
        carp "Method and path are required";
        return;
    }

    my $code = $params{code};
    # Supports only CODE as route destination
    if (!$code || !(ref($code) eq 'CODE')) {
        carp "Invalid route params for $method $path";
        return;
    }

    my @pp;
    for my $key (qw(params named)) {
        my $next_param = Raisin::Util::iterate_params($params{$key} || []);
        while (my ($type, $spec) = $next_param->()) {
            last unless $type;

            push @pp, Raisin::Param->new(
                named => $key eq 'named',
                type => $type, # -> requires/optional
                spec => $spec, # -> { name => ..., type => ... }
            );
        }
    }

    if (ref($path) && ref($path) ne 'Regexp') {
        print STDERR "Route `$path` should be SCALAR or Regexp\n";
        return;
    }

    # Cut off the last slash from a path
    $path =~ s#(.+)/$#$1# if !ref($path);

    my $ep = Raisin::Routes::Endpoint->new(
        code => $code,
        method => $method,
        params => \@pp,
        path => $path,

        desc => $params{desc},
        entity => $params{entity},
        summary => $params{summary},
        tags => $params{tags},
        produces => $params{produces},
    );
    push @{ $self->{routes} }, $ep;

    if ($self->list->{$path}{$method}) {
        Raisin::log(warn => "route has been redefined: $method $path");
    }

    $self->list->{$path}{$method} = scalar @{ $self->{routes} };
}

sub find {
    my ($self, $method, $path) = @_;

    my $cache_key = lc "$method:$path";
    my $routes
        = exists $self->cache->{$cache_key}
        ? $self->cache->{$cache_key}
        : $self->routes;

    my @found = grep { $_->match($method, $path) } @$routes or return;

    if (scalar @found > 1) {
        Raisin::log(warn => "more then one route has been found: $method $path");
    }

    $self->cache->{$cache_key} = \@found;
    $found[0];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Raisin::Routes - A routing class for Raisin.

=head1 VERSION

version 0.94

=head1 SYNOPSIS

    use Raisin::Routes;
    my $r = Raisin::Routes->new;

    my $params = { require => ['name', ], };
    my $code = sub { { name => $params{name} } }

    $r->add(
        method => 'GET',
        path   => '/user',
        params => $params,
        code   => $code
    );
    my $route = $r->find('GET', '/user');

=head1 DESCRIPTION

The router provides the connection between the HTTP requests and the web
application code.

=over

=item B<Adding routes>

    $r->add(method => 'GET', path => '/user', params => $params, code => $code);

=item B<Looking for a route>

    $r->find($method, $path);

=back

=head1 PLACEHOLDERS

Regexp

    qr#/user/(\d+)#

Required

    /user/:id

Optional

    /user/?id

=head1 METHODS

=head2 add

Adds a new route

=head2 find

Looking for a route

=head1 ACKNOWLEDGEMENTS

This module was inspired by L<Kelp::Routes>.

=head1 AUTHOR

Artur Khabibullin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Artur Khabibullin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
