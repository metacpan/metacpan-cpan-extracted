package Router::Pygmy;
$Router::Pygmy::VERSION = '0.05';
use strict;
use warnings;

# ABSTRACT: ultrasimple path router matching paths to names and args


use Carp;
use Router::Pygmy::Route;

my ( $PATH_PART_IDX, $ARG_IDX, $ROUTE_IDX ) = 0 .. 2;

sub new {
    my $class  = shift;
    my $router = bless(
        {
            lookup    => [],
            route_for => {},
        },
        $class
    );
    if (@_) {

        # so far only
        # routes => \%routes
        # or
        # { routes => \%routes }
        # is allowed
        my %args = ref $_[0] && ref $_[0] eq 'HASH' ? %{ $_[0] } : @_;

        if ( my $routes = $args{routes} ) {
            for my $spec ( keys %$routes ) {
                $router->add_route( $spec, $routes->{$spec} );
            }
        }
    }

    return $router;
}

sub new_route {
    my $this = shift;
    return Router::Pygmy::Route->parse(@_);
}

sub add_route {
    my ( $this, $spec, $name ) = @_;

    if ( my $duplicit_route = $this->{route_for}{$name} ) {
        croak sprintf "Duplicit routes for '$name' ('%s', '%s')",
          $duplicit_route->spec, $spec;
    }

    my $route  = $this->new_route($spec);
    my $lookup = $this->{lookup};
    for my $part ( @{ $route->parts } ) {
        $lookup = (
            defined($part)
            ? $lookup->[$PATH_PART_IDX]{$part}
            : $lookup->[$ARG_IDX]
        ) ||= [];
    }

    if ( my $duplicit_name = $lookup->[$ROUTE_IDX] ) {
        my $duplicit_route = $this->{route_for}{$duplicit_name};
        croak sprintf "Identical routes '%s', '%s'",
          $duplicit_route->spec, $route->spec;
    }

    $lookup->[$ROUTE_IDX] = $name;
    $this->{route_for}{$name} = $route;
    return $route;
}

# uri for
sub path_for {
    my $this = shift;
    my $name = shift;

    my $route = $this->{route_for}{$name}
      or croak "No route '$name'";
    return $route->path_for(@_);
}

# return (name, \@args)
sub match {
    my ( $this, $path ) = @_;

    my @parts = grep { length($_) > 0  } split m{/}, $path;
    my @args;

    my $lookup = $this->{lookup};

    while (@parts) {
        my $part = shift @parts;

        if ( my $by_path_part = $lookup->[$PATH_PART_IDX]{$part} ) {
            $lookup = $by_path_part;
        }
        elsif ( my $by_arg = $lookup->[$ARG_IDX] ) {
            push @args, $part;
            $lookup = $by_arg;
        }
        else {
            return;
        }
    }

    my $name = $lookup && $lookup->[$ROUTE_IDX];
    return $name ? ( $name, \@args ) : ();
}

sub match_named {
    my $this = shift;

    my ($name, $args) = $this->match(@_) or return;
    my $route = $this->{route_for}{$name};
    my $names = $route->arg_names;
    my $i = 0;
    return ( $name, [ map { ($names->[$i++] => $_) } @$args ]);
}

1;
# vim: expandtab:shiftwidth=4:tabstop=4:softtabstop=0:textwidth=78: 

__END__

=pod

=encoding UTF-8

=head1 NAME

Router::Pygmy - ultrasimple path router matching paths to names and args

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    use Router::Pygmy;

    my $router = Router::Pygmy->new;
    $router->add_route( 'tree/:species/branches',    'tree.branches' );
    $router->add_route( 'tree/:species/:branch',     'tree.branch' );
    $router->add_route( 'tree/:species/:branch/nut', 'tree.nut' );

    # mapping path to ($name, \@args) or  ($name, \%params)

    my ($name, $args) =  $router->match('tree/oak/branches'); # yields ('tree.branches', ['oak'] )
    my ($name, $params) = $router->match_named('tree/oak/branches'); # yields ('tree.branches', [species=>'oak']) 

    my ($name, $args) = $router->match('tree/oak/12'); # yields ('tree.branch', [ 'oak', 12 ] )
    my ($name, $params) = $router->match_named('tree/oak/12'); # yields ('tree.branch', [ species=> 'oak', branch => 12 ] )

    my ($name, $args) = $router->match('tree/oak/12/ut'); # yields ()

    # branches cannot serve as a value for :branch parameter
    my ($name, $args) = $router->match('tree/oak/branches/nut'); # yields () not ('tree.branches', ['branches'])

    # reverse routing
    #
    # mapping ($name, \%args) or ($name, \@args) to $path

    # path arguments can be \@args (positional), \%params (named) or $arg (single positional)
    my $path = $router->path_for( 'tree.branches', ['ash'] ); # yields 'tree/ash/branches' 
    my $path = $router->path_for( 'tree.branches', 'ash' ); # yields 'tree/ash/branches' 
    my $path = $router->path_for( 'tree.branches', { species => 'ash' } ); # yields 'tree/ash/branches'


    # If you supply invalid number or invalid names of args an exception is thrown
    my $path = $router->path_for( 'tree.branches', { pecies => 'ash' } );
    # throws "Invalid args for route 'tree/:species/branches', got ('pecies') expected ('species')"

    # If name cannot be found, also the error is thrown
    my $path = $router->path_for( 'tree.root', [ 'ash', 12, 3 ] );
    # throws "No route 'tree.root'"

=head1 DESCRIPTION

Router::Pygmy is a very simple straightforward router which maps paths to (name, args) and vice versa.

=head1 METHODS

=over 4

=item C<new> 

  my $router = Router::Pygmy->new;
  my $router = Router::Pygmy->new(routes => \%hash );

a constructor

=item C<add_route($route, $name)>

    $router->add_route( 'tree/:species/branches', 'tree.branches' );

Adds mapping. Both C<$path> and C<$name> args must be strings. The C<$route> can contain parameter names
in form of C<:>I<identifier>. You cannot (intentionally) have two paths leading to the same name.

=item C<match($path)>

    my ($name, $args) = $router->match("tree/walnut/branches");

Maps C<$path> to list ($name, $args) where C<$args> is the arrayref of values of path params.
Returns an empty list if no route matches.

=item C<match_named($path)>

    my ($name, $args) = $router->match_named("tree/walnut/branches");

Same as C<match> only the second element of the list is an arrayref with key
value pairs [ param_name => param_value, param_name => param_value ] 

=item C<path_for($name, $args)>

Constructs the path for a C<$name>

    my $path = $router->path_for("tree.branches", ["walnut"]);

The C<$args> can be either positional, names single string or nothing (if path has no parameter)

=back

=head1 Simplicity 

Route::Pygmy is very simple and thuse maybe of limited use. There are no
parameter validations, no default param values, "the target" is always
a string.

Also it must be noted that fixed parts have an absolute precedence over parameters.
If two routes shares the start and then one follows with a fixed part 
and the other one with a parameter, then the parameter can never have the value
of fixed part even if it leads to no match. It is also the intention.

Having routes like this:

    $router->add_route( 'tree/:species/branches', 'tree.branches' );
    $router->add_route( 'tree/search', 'tree.search' );

the path C<tree/search/branches> doesnot match.

At the other hand the mapping is fast. For the direct mapping path to (C<$name>, C<$args>)
it is a simple DFA, the reverse mapping (C<$name>, C<$args>) is a simple hash lookup.

=head1 DEPENDENCIES

None so far.

=head1 AUTHOR

Roman Daniel <roman.daniel@davosro.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Roman Daniel.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
