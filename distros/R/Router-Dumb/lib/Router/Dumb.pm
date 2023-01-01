use 5.14.0;
package Router::Dumb 0.006;
use Moose;
# ABSTRACT: yet another dumb path router for URLs

#pod =head1 SYNOPSIS
#pod
#pod   my $r = Router::Dumb->new;
#pod
#pod   $r->add_route(
#pod     Router::Dumb::Route->new({
#pod       parts       => [ qw(group :group uid :uid) ],
#pod       target      => 'pants',
#pod       constraints => {
#pod         group => find_type_constraint('Int'),
#pod       },
#pod     }),
#pod   );
#pod
#pod   my $match = $r->route( '/group/123/uid/321' );
#pod   
#pod   # $match->target  returns 'pants'
#pod   # $match->matches returns (group => 123, uid => 321)
#pod
#pod =head1 DESCRIPTION
#pod
#pod Router::Dumb provides a pretty dumb router.  You can add routes and then ask
#pod how to route a given path string.
#pod
#pod Routes have a path.  A path is an arrayref of names.  Names that start with a
#pod colon are placeholders.  Everything else is a literal.  Literals pieces must
#pod appear, literally, in the string being routed.  A placeholder can be satisfied
#pod by any value, as long as it satisfies the placeholder's constraint.  If there's
#pod no constraint, any value works.
#pod
#pod The special part C<*> can be used to mean "...then capture everything else into
#pod the placeholder named C<REST>."
#pod
#pod Most of the time, you won't be calling C<add_route>, but using some other
#pod helper to figure out routes to add for you.  Router::Dumb ships with
#pod L<Router::Dumb::Helper::FileMapper> and L<Router::Dumb::Helper::RouteFile>.
#pod
#pod =cut

use Router::Dumb::Route;

use namespace::autoclean;

#pod =method add_route
#pod
#pod   $router->add_route(
#pod     Router::Dumb::Route->new({
#pod       parts  => [ qw( the :path parts ) ],
#pod       target => 'target-string',
#pod       constraints => {
#pod         path => $moose_tc,
#pod       },
#pod     })
#pod   );
#pod
#pod This method adds a new L<route|Router::Dumb::Route> to the router.
#pod
#pod =cut

sub add_route {
  my ($self, $route) = @_;

  confess "invalid route" unless $route->isa('Router::Dumb::Route');

  my $npath = $route->normalized_path;
  if (my $existing = $self->_route_at( $npath )) {
    confess sprintf(
      "route conflict: %s would conflict with %s",
      $route->path,
      $existing->path,
    );
  }

  $self->_add_route($npath, $route);
}

#pod =method add_route_unless_exists
#pod
#pod   $router->add_route_unless_exists(
#pod     Router::Dumb::Route->new({
#pod       parts  => [ qw( the :path parts ) ],
#pod       target => 'target-string',
#pod       ...
#pod     })
#pod   );
#pod
#pod This method adds a new L<route|Router::Dumb::Route> to the router unless it
#pod would conflict, in which case it does nothing.
#pod
#pod =cut

sub add_route_unless_exists {
  my ($self, $route) = @_;

  confess "invalid route" unless $route->isa('Router::Dumb::Route');

  my $npath = $route->normalized_path;
  return if $self->_route_at( $npath );

  $self->_add_route($npath, $route);
}

#pod =method route
#pod
#pod   my $match_or_undef = $router->route( $str );
#pod
#pod If the given string can be routed to a match, the L<match|Router::Dumb::Match>
#pod is returned.  If not, the method returns false.
#pod
#pod The string must begin with a C</>.
#pod
#pod =cut

sub route {
  my ($self, $str) = @_;

  # Shamelessly stolen from Path::Router 0.10 -- rjbs, 2011-07-13
  $str =~ s|/{2,}|/|g;                          # xx////xx  -> xx/xx
  $str =~ s{(?:/\.)+(?:/|\z)}{/}g;              # xx/././xx -> xx/xx
  $str =~ s|^(?:\./)+||s unless $str eq "./";   # ./xx      -> xx
  $str =~ s|^/(?:\.\./)+|/|;                    # /../../xx -> xx
  $str =~ s|^/\.\.$|/|;                         # /..       -> /
  $str =~ s|/\z|| unless $str eq "/";           # xx/       -> xx

  confess "path didn't start with /" unless $str =~ s{^/}{};

  if (my $route = $self->_route_at($str)) {
    # should always match! -- rjbs, 2011-07-13
    confess "empty route didn't match empty path"
      unless my $match = $route->check($str);

    return $match;
  }

  my @parts = split m{/}, $str;

  for my $candidate ($self->ordered_routes(
    sub {
         ($_->part_count == @parts and $_->has_params)
      or ($_->part_count <= @parts and $_->is_slurpy)
    }
  )) {
    next unless my $match = $candidate->check($str);
    return $match;
  }

  return;
}

has _route_map => (
  is   => 'ro',
  isa  => 'HashRef',
  init_arg => undef,
  default  => sub {  {}  },
  traits   => [ 'Hash' ],
  handles  => {
    _routes   => 'values',
    _route_at => 'get',
    _add_route => 'set',
  },
);

#pod =method ordered_routes
#pod
#pod   my @routes = $router->ordered_routes;
#pod
#pod This method returns the router's routes, in the order that they will be
#pod checked.  You probably do not want to use this method unless you really know
#pod what you're doing.
#pod
#pod =cut

sub ordered_routes {
  my ($self, $filter) = @_;

  return sort { $b->part_count <=> $a->part_count
             || $a->is_slurpy  <=> $b->is_slurpy }
         grep { $filter ? $filter->() : 1 }
         $self->_routes;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Router::Dumb - yet another dumb path router for URLs

=head1 VERSION

version 0.006

=head1 SYNOPSIS

  my $r = Router::Dumb->new;

  $r->add_route(
    Router::Dumb::Route->new({
      parts       => [ qw(group :group uid :uid) ],
      target      => 'pants',
      constraints => {
        group => find_type_constraint('Int'),
      },
    }),
  );

  my $match = $r->route( '/group/123/uid/321' );
  
  # $match->target  returns 'pants'
  # $match->matches returns (group => 123, uid => 321)

=head1 DESCRIPTION

Router::Dumb provides a pretty dumb router.  You can add routes and then ask
how to route a given path string.

Routes have a path.  A path is an arrayref of names.  Names that start with a
colon are placeholders.  Everything else is a literal.  Literals pieces must
appear, literally, in the string being routed.  A placeholder can be satisfied
by any value, as long as it satisfies the placeholder's constraint.  If there's
no constraint, any value works.

The special part C<*> can be used to mean "...then capture everything else into
the placeholder named C<REST>."

Most of the time, you won't be calling C<add_route>, but using some other
helper to figure out routes to add for you.  Router::Dumb ships with
L<Router::Dumb::Helper::FileMapper> and L<Router::Dumb::Helper::RouteFile>.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 METHODS

=head2 add_route

  $router->add_route(
    Router::Dumb::Route->new({
      parts  => [ qw( the :path parts ) ],
      target => 'target-string',
      constraints => {
        path => $moose_tc,
      },
    })
  );

This method adds a new L<route|Router::Dumb::Route> to the router.

=head2 add_route_unless_exists

  $router->add_route_unless_exists(
    Router::Dumb::Route->new({
      parts  => [ qw( the :path parts ) ],
      target => 'target-string',
      ...
    })
  );

This method adds a new L<route|Router::Dumb::Route> to the router unless it
would conflict, in which case it does nothing.

=head2 route

  my $match_or_undef = $router->route( $str );

If the given string can be routed to a match, the L<match|Router::Dumb::Match>
is returned.  If not, the method returns false.

The string must begin with a C</>.

=head2 ordered_routes

  my @routes = $router->ordered_routes;

This method returns the router's routes, in the order that they will be
checked.  You probably do not want to use this method unless you really know
what you're doing.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Ricardo Signes

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Ricardo Signes <rjbs@semiotic.systems>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
