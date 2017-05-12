package Routes::Tiny;

use strict;
use warnings;

require Carp;
require Scalar::Util;
use Routes::Tiny::Pattern;

our $VERSION = 0.19;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{strict_trailing_slash} = $params{strict_trailing_slash};
    $self->{default_method} = $params{default_method};

    $self->{parent_pattern}        = undef;
    $self->{patterns}              = [];
    $self->{names}                 = {};
    $self->{strict_trailing_slash} = 1
      unless defined $self->{strict_trailing_slash};

    return $self;
}

sub add_route {
    my $self = shift;
    my ($pattern, @args) = @_;

    $pattern = $self->_build_pattern(
        strict_trailing_slash => $self->{strict_trailing_slash},
        default_method		  => $self->{default_method},
        routes                => $self,
        pattern               => $pattern,
        @args
    );

    push @{$self->{patterns}}, $pattern;

    $self->_register_pattern_name($pattern) if $pattern->{name};

    return $pattern;
}

sub mount {
    my $self = shift;
    my ($pattern, $routes, @args) = @_;

    $pattern = $self->add_route($pattern, subroutes => $routes, @args);
    $routes->{parent_pattern} = $pattern;
    $self->_register_pattern_name($_) for values %{ $routes->{names} };
    Scalar::Util::weaken($routes->{parent_pattern});
    return $pattern;
}

sub match {
    my $self = shift;
    my ($path, @args) = @_;

    foreach my $pattern (@{$self->{patterns}}) {
        if (my $m = $pattern->match($path, @args)) {
            return $m;
        }
    }

    return;
}

sub build_path {
    my $self = shift;
    my ($name, @args) = @_;

    my $pattern = $self->{names}->{$name};

    return $pattern->build_path(@args) if $pattern;

    Carp::croak("Unknown name '$name' used to build a path");
}

sub _register_pattern_name {
    my $self = shift;
    my ($pattern) = @_;

    my $name = $pattern->name;
    if (exists $self->{names}->{ $name }) {
        Carp::carp("pattern name '$name' already used");
    }
    else {
        $self->{names}->{ $name } = $pattern;
        my $parent_routes = $self->{parent_pattern} && $self->{parent_pattern}->{routes};
        if ($parent_routes) {
            $parent_routes->_register_pattern_name(@_);
        }
    }
}

sub _build_pattern { shift; return Routes::Tiny::Pattern->new(@_) }

1;
__END__

=head1 NAME

Routes::Tiny - Routes

=head1 SYNOPSIS

    my $routes = Routes::Tiny->new;

    # Constraints
    $routes->add_route('/articles/:id', constraints => {id => qr/\d+/});

    # Optional placeholders
    $routes->add_route('/archive/:year/(:month)?');

    # Defaults
    $routes->add_route('/articles/:id',
        defaults => {controller => 'bar', action => 'foo'});

    # Grouping (matches 'hello-bar')
    $routes->add_route('/(:foo)-bar');

    # Globbing (matches 'photos/foo/bar/baz')
    $routes->add_route('/photos/*other');

    # Path building
    $routes->add_route('/:foo/:bar', name => 'default');
    $routes->build_path('default', foo => 'hello', bar => 'world');

    # Matching
    my $match = $routes->match('/hello/world');
    my $captures_hashref = $match->captures;

    # Matching with method
    my $match = $routes->match('/hello/world', method => 'GET');

    # Subroutes
    my $subroutes = Routes::Tiny->new;
    $subroutes->add_route('/article/:id');
    $routes->mount('/admin/', $subroutes);

=head1 DESCRIPTION

L<Routes::Tiny> is a lightweight routes implementation.

L<Routes::Tiny> aims to be easy to use in any web framework.

=head1 FEATURES

=head2 C<Constraints>

    $routes->add_route('/articles/:id', constraints => {id => qr/\d+/});

    $match = $routes->match('/articles/1');  # Routes::Tiny::Match object
    $match = $routes->match('/article/foo'); # undef

It is possible to specify a constraint that a placeholder must match using a
normal Perl regular expression.

Constraints can be passed as array references:

    $routes->add_route('/articles/:action',
        constraints => {action => [qw/add update/]});

    $match = $routes->match('/articles/add');    # Routes::Tiny::Match object
    $match = $routes->match('/articles/delete'); # undef

=head2 C<Optional placeholders>

    $routes->add_route('/admin/:service(/:action)?', defaults => {action => 'list'});

    my $match = $routes->match('/admin/foo');
    # $m->captures is {service => 'foo', action => 'list'}

It is possible to specify an optional placeholder with a default value.

=head2 C<Grouping>

    $routes->add_route('/(:foo)-bar');

    $match = $routes->match('/hello-bar');
    # $match->captures is {foo => 'hello'}

It is possible to create a placeholder that doesn't occupy all the space between
slashes.

=head2 C<Globbing>

    $routes->add_route('/photos/*other');
    $routes->add_route('/books/*section/:title');
    $routes->add_route('/*a/foo/*b');

    $match = $routes->match('photos/foo/bar/baz');
    # $match->captures is {other => 'foo/bar/baz'}

    $match = $routes->match('books/some/section/last-words-a-memoir');
    # $match->captures is {section => 'some/section', title => 'last-words-a-memoir'}

    $match = $routes->match('zoo/woo/foo/bar/baz');
    # $match->captures is {a => 'zoo/woo', b => 'bar/baz'}

It is possible to specify a globbing placeholder.

=head2 C<Passing arguments AS IS>

    $routes->add_route('/', arguments => {one => 'two'});

    $match = $routes->match('/');
    # $match->arguments is {one => 'two'}

It is possible to pass arguments to the match object AS IS.

=head2 C<Path building>

    $routes->add_route('/articles/:id', name => 'article');

    $path = $routes->build_path('article', id => 123);
    # $path is '/articles/123'

It is possible to reconstruct a path from route's name and parameters.

=head2 C<Subroutes>

    $subroutes = Routes::Tiny->new;
    $subroutes->add_route('/articles/:id', name => 'admin-article');
    $routes->mount('/admin/', $subroutes);

    $match = $routes->match('/admin/articles/3/');
    # $match->captures is {id => 3}

It is possible to capture params in mount routes

    $subroutes = Routes::Tiny->new;
    $subroutes->add_route('/comments/:page/', name => 'comments');
    $routes->mount('/:type/:id/', $subroutes);

    $match = $routes->match('/articles/3/comments/5/');
    # $match->captures is {page => 5}
    # $match->parent->captures is {type => 'articles', id => 3}

Parent routes mounts names of children routes, so it's possible to buil path

    $path = $routes->build_path('admin-article', id => 123);
    # $path is '/admin/articles/123'
    $path = $routes->build_path('comments', type => 'articles', id => 123, page => 5);
    # $path is '/articles/123/comments/5/'

=head1 WARNINGS

=head2 C<Trailing slash issue>

Trailing slash is important.

    $routes->add_route('/articles');

    # is different from

    $routes->add_route('/articles/');

If you don't want this behaviour pass C<strict_trailing_slash> to the constructor:

    my $routes = Routes::Tiny->new(strict_trailing_slash => 0);

=head1 METHODS

=head2 C<new>

    my $routes = Routes::Tiny->new;

=head2 C<add_route>

    $routes->add_route('/:service/:action');

Add a new route.

=head2 C<mount>

    $routes->mount('/admin/', $subroutes)

Includes one Routes::Tiny instance into another with given prefix.

=head2 C<match>

    $routes->match('/hello/world');

Match against a path.

=head2 C<build_path>

    $pattern->build_path('name', {foo => 'bar'});

Build path from a given name and params.

=head1 DEVELOPMENT

=head2 Repository

    http://github.com/vti/routes-tiny

=head1 CREDITS

Sergey Zasenko (und3f)

Roman Galeev (jamhed)

Dmitry Smal (mialinx)

Dinar (ziontab)

Jonathan R. Warden

Alexander Batyrshin

Konstantin Cherednichenko

=head1 AUTHOR

Viacheslav Tykhanovskyi, C<vti@cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2017, Viacheslav Tykhanovskyi

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
