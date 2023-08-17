package Slick::RouteManager;

use 5.036;

use Moo::Role;

use Types::Standard qw(Str);
use Slick::Events   qw(EVENTS);
use Slick::Methods  qw(METHODS);

has base => (
    is      => 'ro',
    isa     => Str,
    default => ''
);

has handlers => (
    is      => 'rw',
    default => sub { return Slick::RouteMap->new; }
);

foreach my $meth ( @{ METHODS() } ) {
    Slick::Util::monkey_patch(
        __PACKAGE__,
        $meth => sub {
            my ( $self, $route, $callback, $events ) = @_;

            $route = '/' . $route
              if ( $route ne '' ) && ( rindex( $route, '/', 0 ) != 0 );

            $route = $self->base . $route if $self->base;

            my $route_object = Slick::Route->new(
                callback => $callback,
                route    => $route
            );

            if ($events) {
                foreach my $event ( EVENTS->@* ) {
                    $route_object->on( $event, $_ )
                      for ( @{ $events->{$event} } );
                }
            }

            $self->handlers->add( $route_object, $meth );

            return $route_object;
        }
    );
}

sub BUILD {
    my $self = shift;

    $self->{base} = '/' . $self->base
      if ( $self->base ne '' ) && ( rindex( $self->base, '/', 0 ) != 0 );

    return $self;
}

1;

=encoding utf8

=head1 NAME

Slick::RouteManager

=head1 SYNOPSIS

A L<Moo::Role> that allows the managing of routes via a L<Slick::RouteMap> and HTTP methods.

=over 2

=item * L<Slick>

=item * L<Slick::Router>

=item * L<Slick::Context>

=item * L<Slick::Database>

=item * L<Slick::DatabaseExecutor>

=item * L<Slick::DatabaseExecutor::MySQL>

=item * L<Slick::DatabaseExecutor::Pg>

=item * L<Slick::EventHandler>

=item * L<Slick::Events>

=item * L<Slick::Methods>

=item * L<Slick::RouteMap>

=item * L<Slick::Util>

=back

=cut
