package Path::Router;
our $AUTHORITY = 'cpan:STEVAN';
$Path::Router::VERSION = '0.15';
use 5.008;
use Carp             1.32;
use Eval::Closure    0.13;
use File::Spec::Unix 3.40     ();
use Try::Tiny        0.19;
use Types::Standard  1.000005 -types;

use Path::Router::Types;
use Path::Router::Route;
use Path::Router::Route::Match;

use Moo              2.000001;
use namespace::clean 0.23;
# ABSTRACT: A tool for routing paths


use constant         1.24 DEBUG => exists $ENV{PATH_ROUTER_DEBUG} ? $ENV{PATH_ROUTER_DEBUG} : 0;

has 'routes' => (
    is      => 'ro',
    isa     => ArrayRef[InstanceOf['Path::Router::Route']],
    default => sub { [] },
);

has 'route_class' => (
    is      => 'ro',
    isa     => ClassName,
    default => 'Path::Router::Route',
);

has 'inline' => (
    is      => 'rw',
    isa     => Bool,
    default => 1,
    trigger => sub { $_[0]->clear_match_code }
);

has 'match_code' => (
    is      => 'rw',
    isa     => CodeRef,
    lazy    => 1,
    builder => 1,
    clearer => 'clear_match_code'
);

sub _build_match_code {
    my $self = shift;

    my @code;
    my $i = 0;
    foreach my $route (@{$self->routes}) {
        push @code, $route->generate_match_code($i++);
    }

    return eval_closure(
        source => [
            'sub {',
                '#line ' . __LINE__ . ' "' . __FILE__ . '"',
                'my $self = shift;',
                'my $path = shift;',
                'my $routes = $self->routes;',
                'my @matches;',
                @code,
                '#line ' . __LINE__ . ' "' . __FILE__ . '"',
                'if (@matches == 0) {',
                    'print STDERR "match failed\n" if Path::Router::DEBUG();',
                    'return;',
                '}',
                'elsif (@matches == 1) {',
                    'return $matches[0];',
                '}',
                'else {',
                    'return $self->_disambiguate_matches($path, @matches);',
                '}',
            '}',
        ]
    );
}

sub add_route {
    my ($self, $path, %options) = @_;
    push @{$self->routes} => $self->route_class->new(
        path  => $path,
        %options
    );
    $self->clear_match_code;
}

sub insert_route {
    my ($self, $path, %options) = @_;
    my $at = delete $options{at} || 0;

    my $route = $self->route_class->new(
        path  => $path,
        %options
    );
    my $routes = $self->routes;

    if (! $at) {
        unshift @$routes, $route;
    } elsif ($#{$routes} < $at) {
        push @$routes, $route;
    } else {
        splice @$routes, $at, 0, $route;
    }
    $self->clear_match_code;
}

sub include_router {
    my ($self, $path, $router) = @_;

    ($path eq '' || $path =~ /\/$/)
        || confess "Path is either empty or does not end with /";

    push @{ $self->routes } => map {
            $_->clone( path => ($path . $_->path) )
        } @{ $router->routes };
    $self->clear_match_code;
}

sub match {
    my ($self, $url) = @_;
    $url = File::Spec::Unix->canonpath($url);
    $url =~ s|^/||; # Path::Router specific. remove first /

    if ($self->inline) {
        return $self->match_code->($self, $url);
    } else {
        my @parts = split '/' => $url;

        my @matches;
        for my $route (@{$self->routes}) {
            my $match = $route->match(\@parts) or next;
            push @matches, $match;
        }
        return             if @matches == 0;
        return $matches[0] if @matches == 1;
        return $self->_disambiguate_matches($url, @matches);
    }
    return;
}

sub _disambiguate_matches {
    my $self = shift;
    my ($path, @matches) = @_;

    my $min;
    my @found;
    for my $match (@matches) {
        my $vars = @{ $match->route->required_variable_component_names };
        if (!defined($min) || $vars < $min) {
            @found = ($match);
            $min = $vars;
        }
        elsif ($vars == $min) {
            push @found, $match;
        }
    }

    confess "Ambiguous match: path $path could match any of "
      . join(', ', sort map { $_->route->path } @found)
        if @found > 1;

    return $found[0];
}

sub uri_for {
    my ($self, %orig_url_map) = @_;

    # anything => undef is useless; ignore it and let the defaults override it
    for (keys %orig_url_map) {
        delete $orig_url_map{$_} unless defined $orig_url_map{$_};
    }

    my @possible;
    foreach my $route (@{$self->routes}) {
        local $SIG{__DIE__};

        my @url;
        my $url = try {

            my %url_map = %orig_url_map;

            my %required = map {( $_ => 1 )}
                @{ $route->required_variable_component_names };

            my %optional = map {( $_ => 1 )}
                @{ $route->optional_variable_component_names };

            my %url_defaults;

            my %match = %{$route->defaults || {}};

            for my $component (keys(%required), keys(%optional)) {
                next unless exists $match{$component};
                $url_defaults{$component} = delete $match{$component};
            }
            # any remaining keys in %defaults are 'extra' -- they don't appear
            # in the url, so they need to match exactly rather than being
            # filled in

            %url_map = (%url_defaults, %url_map);

            my @keys = keys %url_map;

            if (DEBUG) {
                warn "> Attempting to match ", $route->path, " to (", (join " / " => @keys), ")";
            }
            (
                @keys >= keys(%required) &&
                @keys <= (keys(%required) + keys(%optional) + keys(%match))
            ) || die "LENGTH DID NOT MATCH\n";

            if (my @missing = grep { ! exists $url_map{$_} } keys %required) {
                warn "missing: @missing" if DEBUG;
                die "MISSING ITEM [@missing]\n";
            }

            if (my @extra = grep {
                    ! $required{$_} && ! $optional{$_} && ! $match{$_}
                } keys %url_map) {
                warn "extra: @extra" if DEBUG;
                die "EXTRA ITEM [@extra]\n";
            }

            if (my @nomatch = grep {
                    exists $url_map{$_} and $url_map{$_} ne $match{$_}
                } keys %match) {
                warn "no match: @nomatch" if DEBUG;
                die "NO MATCH [@nomatch]\n";
            }

            for my $component (@{$route->components}) {
                if ($route->is_component_variable($component)) {
                    warn "\t\t... found a variable ($component)" if DEBUG;
                    my $name = $route->get_component_name($component);

                    push @url => $url_map{$name}
                        unless
                        $route->is_component_optional($component) &&
                        $route->defaults->{$name}                 &&
                        $route->defaults->{$name} eq $url_map{$name};

                }

                else {
                    warn "\t\t... found a constant ($component)" if DEBUG;

                    push @url => $component;
                }

                warn "+++ URL so far ... ", (join "/" => @url) if DEBUG;
            }

            return join "/" => grep { defined } @url;
        }
        catch {
            do {
                warn join "/" => @url;
                warn "... ", $_;
            } if DEBUG;

            return;
        };

        push @possible, [$route, $url] if defined $url;
    }

    return undef unless @possible;
    return $possible[0][1] if @possible == 1;

    my @found;
    my $min;
    for my $possible (@possible) {
        my ($route, $url) = @$possible;

        my %url_map = %orig_url_map;

        my %required = map {( $_ => 1 )}
            @{ $route->required_variable_component_names };

        my %optional = map {( $_ => 1 )}
            @{ $route->optional_variable_component_names };

        my %url_defaults;

        my %match = %{$route->defaults || {}};

        for my $component (keys(%required), keys(%optional)) {
            next unless exists $match{$component};
            $url_defaults{$component} = delete $match{$component};
        }
        # any remaining keys in %defaults are 'extra' -- they don't appear
        # in the url, so they need to match exactly rather than being
        # filled in

        %url_map = (%url_defaults, %url_map);

        my %wanted = (%required, %optional, %match);
        delete $wanted{$_} for keys %url_map;

        my $extra = keys %wanted;

        if (!defined($min) || $extra < $min) {
            @found = ($possible);
            $min = $extra;
        }
        elsif ($extra == $min) {
            push @found, $possible;
        }
    }

    confess "Ambiguous path descriptor (specified keys "
      . join(', ', sort keys(%orig_url_map))
      . "): could match paths "
      . join(', ', sort map { $_->path } map { $_->[0] } @found)
        if @found > 1;

    return $found[0][1];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::Router - A tool for routing paths

=head1 VERSION

version 0.15

=head1 SYNOPSIS

  my $router = Path::Router->new;

  $router->add_route('blog' => (
      defaults => {
          controller => 'blog',
          action     => 'index',
      },
      # you can provide a fixed "target"
      # for a match as well, this can be
      # anything you want it to be ...
      target => My::App->get_controller('blog')->get_action('index')
  ));

  $router->add_route('blog/:year/:month/:day' => (
      defaults => {
          controller => 'blog',
          action     => 'show_date',
      },
      # validate with ...
      validations => {
          # ... raw-Regexp refs
          year       => qr/\d{4}/,
          # ... custom Moose types you created
          month      => 'NumericMonth',
          # ... Moose anon-subtypes created inline
          day        => subtype('Int' => where { $_ <= 31 }),
      }
  ));

  $router->add_route('blog/:action/?:id' => (
      defaults => {
          controller => 'blog',
      },
      validations => {
          action  => qr/\D+/,
          id      => 'Int',  # also use plain Moose types too
      }
  ));

  # even include other routers
  $router->include_router( 'polls/' => $another_router );

  # ... in your dispatcher

  # returns a Path::Router::Route::Match object
  my $match = $router->match('/blog/edit/15');

  # ... in your code

  my $uri = $router->uri_for(
      controller => 'blog',
      action     => 'show_date',
      year       => 2006,
      month      => 10,
      day        => 5,
  );

=head1 DESCRIPTION

This module provides a way of deconstructing paths into parameters
suitable for dispatching on. It also provides the inverse in that
it will take a list of parameters, and construct an appropriate
uri for it.

=head2 Reversable

This module places a high degree of importance on reversability.
The value produced by a path match can be passed back in and you
will get the same path you originally put in. The result of this
is that it removes ambiguity and therefore reduces the number of
possible mis-routings.

=head2 Verifyable

This module also provides additional tools you can use to test
and verify the integrity of your router. These include:

=over 4

=item *

An interactive shell in which you can test various paths and see the
match it will return, and also test the reversability of that match.

=item *

A L<Test::Path::Router> module which can be used in your applications
test suite to easily verify the integrity of your paths.

=back

=head1 METHODS

=over 4

=item B<new>

=item B<add_route ($path, ?%options)>

Adds a new route to the I<end> of the routes list.

=item B<insert_route ($path, %options)>

Adds a new route to the routes list. You may specify an C<at> parameter, which would
indicate the position where you want to insert your newly created route. The C<at>
parameter is the C<index> position in the list, so it starts at 0.

Examples:

    # You have more than three paths, insert a new route at
    # the 4th item
    $router->insert_route($path => (
        at => 3, %options
    ));

    # If you have less items than the index, then it's the same as
    # as add_route -- it's just appended to the end of the list
    $router->insert_route($path => (
        at => 1_000_000, %options
    ));

    # If you want to prepend, omit "at", or specify 0
    $router->insert_Route($path => (
        at => 0, %options
    ));

=item B<include_router ( $path, $other_router )>

These extracts all the route from C<$other_router> and includes them into
the invocant router and prepends C<$path> to all their paths.

It should be noted that this does B<not> do any kind of redispatch to the
C<$other_router>, it actually extracts all the paths from C<$other_router>
and inserts them into the invocant router. This means any changes to
C<$other_router> after inclusion will not be reflected in the invocant.

=item B<routes>

=item B<match ($path)>

Return a L<Path::Router::Route::Match> object for the first route that matches the
given C<$path>, or C<undef> if no routes match.

=item B<uri_for (%path_descriptor)>

Find the path that, when passed to C<< $router->match >>, would produce the
given arguments.  Returns the path without any leading C</>.  Returns C<undef>
if no routes match.

=item B<route_class ($classname)>

The class to use for routes.
Defaults to L<Path::Router::Route>.

=item B<meta>

=back

=head1 DEBUGGING

You can turn on the verbose debug logging with the C<PATH_ROUTER_DEBUG>
environment variable.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2011 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=for Pod::Coverage DEBUG

=head1 AUTHOR

Stevan Little <stevan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
