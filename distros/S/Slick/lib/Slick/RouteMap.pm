package Slick::RouteMap;

use 5.036;

use Moo;
use Types::Standard qw(HashRef);
use Slick::Methods  qw(METHODS);
use Slick::Events   qw(EVENTS);
use Carp            qw(croak);
use Scalar::Util    qw(blessed);
use List::Util      qw(first);

has _map => (
    is      => 'ro',
    isa     => HashRef,
    default => sub {
        return {
            '/' => {
                children => {},
                methods  => {}
            }
        };
    }
);

sub add {
    my ( $self, $route, $method ) = @_;

    croak qq{Unrecognized HTTP method $method.}
      unless defined( grep { $_ eq $method } METHODS() );

    chomp( $route->{route} );
    my $uri =
        substr( $route->route, 0, 1 ) eq '/'
      ? substr( $route->route, 1 )
      : $route->route;

    my $m = $self->_map->{'/'};

    my @parts = split /\//x, $uri;
    if ( @parts && substr( $uri, -1 ) eq '/' ) {
        $parts[-1] .= '/';
    }

    for (@parts) {
        if ( exists $m->{children}->{$_} ) {
            $m = $m->{children}->{$_};
        }
        else {
            $m->{children}->{$_} = { children => {} };
            $m = $m->{children}->{$_};
        }
    }

    $m->{methods}->{$method} = $route;

    return $self;
}

## no critic qw(Subroutines::ProhibitExplicitReturnUndef)
sub get {
    my ( $self, $uri, $method, $context ) = @_;

    chomp($uri);

    return $self->_map->{'/'}->{methods}->{$method} if $uri eq '/';

    $uri =
        substr( $uri, 0, 1 ) eq '/'
      ? substr( $uri, 1 )
      : $uri;

    my $m = $self->_map->{'/'};

    my @parts = split /\//x, $uri;
    if ( @parts && substr( $uri, -1 ) eq '/' ) {
        $parts[-1] .= '/';
    }

    my $params = {};
    for (@parts) {
        if ( exists $m->{children}->{$_} ) {
            $m = $m->{children}->{$_};
            next;
        }

        my $param;
        my $part = $_;
        for ( keys %{ $m->{children} } ) {
            ($param) = /^\{([\w_]+)\}$/x;
            $param // next;
            $params->{$param} = $part;
            $m = $m->{children}->{"{$param}"};
            last;
        }

        return undef unless defined $param;
    }

    $context->{params} = $params;

    return $m->{methods}->{$method};
}

# Merge two route maps
sub merge {
    my $self   = shift;
    my $other  = shift;
    my $events = shift;

    my @stack;

    push( @stack,
        $other->{_map}->{'/'} // croak qq{Invalid route map passed.} );

    # FIXME: This may get slow on very large projects, but we'll see.
    while ( my $p = pop @stack ) {
        for ( keys $p->{children}->%* ) {
            push( @stack, $p->{children}->{$_} );
        }

        for ( keys $p->{methods}->%* ) {
            my $route = $p->{methods}->{$_};

            # TODO: This sucks!
            foreach my $event ( EVENTS()->@* ) {
                $route->event_handlers->{$event} = [
                    $events->{$event}->@*,
                    $route->event_handlers->{$event}->@*
                ];
            }

            $self->add( $route, $_ );
        }
    }

    return $self;
}

1;

=encoding utf8

=head1 NAME

Slick::RouteMap

=head1 SYNOPSIS

L<Slick::RouteMap> is a simple "Hash-Trie" that resolves routes extremely fast, at the cost of using slightly more
memory than other routing schemes.

=head1 API

=head2 get

Given a uri (Str), method (Str), and L<Slick::Context>, find the associated L<Slick::Route>, and return it.
Otherwise return C<undef>.

=head2 add

Given a L<Slick::Route> and a uri (Str), add it to the Hash-Trie for later lookup.

=head2 merge

Merges two given L<Slick::RouteMap>s. This is the primary mechanism behind L<Slick::Router>.

=head1 See also

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
