package Salvation::AnyNotify::Plugin::Graphite;

use strict;
use warnings;

use base 'Salvation::AnyNotify::Plugin';

use URI ();
use Socket 'AF_INET', 'AF_INET6';
use AnyEvent ();
use Salvation::TC ();
use Salvation::Method::Signatures;
use Salvation::AnyNotify::Plugin::Graphite::Reader ();

use constant {

    UNPACK_SOCKADDR_MAP => {
        AF_INET() => \&Socket::unpack_sockaddr_in,
        AF_INET6() => \&Socket::unpack_sockaddr_in6,
    },
};

our $VERSION = 0.03;

sub default_graphite_ttl { 1 * 60 * 60 }

method graphite_ttl() {

    return (
        $self -> core() -> config() -> get( 'graphite.connection_ttl' )
        // $self -> default_graphite_ttl()
    );
}

method start() {

    $self -> { 'monitor' } = [];
}

method monitor( Str{1,} :plugin!, ArrayRef|HashRef :spec!, Int :interval!, Int :after ) {

    unless( exists $self -> { "monitor:${plugin}" } ) {

        my $object = $self -> load_plugin(
            infix => 'Monitor', base_name => $plugin,
        );

        die( "Graphite has no monitoring available for ${plugin}" ) unless defined $object;

        $self -> { "monitor:${plugin}" } = $object;
    }

    my @args = ();

    if( ref( $spec ) eq 'HASH' ) {

        @args = %$spec;

    } else {

        @args = @$spec;
    }

    my $watcher = $self -> { "monitor:${plugin}" } -> add( @args );

    Salvation::TC -> assert( $watcher, 'CodeRef' );

    push( @{ $self -> { 'monitor' } }, AnyEvent -> timer(
        cb => $watcher,
        interval => $interval,
        ( defined $after ? ( after => $after ) : () ),
    ) );

    return;
}

method query( Str{1,}|ArrayRef[Str{1,}]{1,} :target!, Str{1,} :from!, Str{1,} :to! ) {

    my $now = time();
    my $instances = $self -> { 'instances' } //= {};

    if(
        exists $instances -> { $$ }
        && ( ( $instances -> { $$ } -> { 'time' } + $self -> graphite_ttl() ) < $now )
    ) {

        delete( $instances -> { $$ } );
    }

    unless( exists $instances -> { $$ } ) {

        $instances -> { $$ } = {
            time => $now,
            graphite => $self -> get_graphite(),
        };
    }

    my $result = eval { $instances -> { $$ } -> { 'graphite' } -> query(
        target => $target,
        from => $from,
        to => $to,
    ) };

    if( $@ ) {

        warn $@;
        delete( $instances -> { $$ } );
        return undef;
    }

    return $result;
}

method get_graphite() {

    my $config = $self -> core() -> config();
    my $hosts = $config -> get( 'graphite.hosts' );

    Salvation::TC -> assert( $hosts, 'ArrayRef[HashRef(
        Str :host!,
        Int :port!
    )]' );

    foreach my $spec ( @$hosts ) {

        my $uri = URI -> new( $spec -> { 'host' } );

        unless( $uri -> scheme() ) {

            $uri = URI -> new( 'http://' . $spec -> { 'host' } );
        }

        my $scheme = $uri -> scheme();

        if(
            ( ( $scheme eq 'http' ) && ( $spec -> { 'port' } == 80 ) )
            || ( ( $scheme eq 'https' ) && ( $spec -> { 'port' } == 443 ) )
        ) {

            $uri -> port( undef );

        } else {

            $uri -> port( $spec -> { 'port' } );
        }

        foreach my $ai ( Socket::getaddrinfo( $uri -> host(), $uri -> port() ) ) {

            next unless Salvation::TC -> is( $ai, 'HashRef( Int :family!, Str{1,} :addr! )' );

            if( defined( my $code = UNPACK_SOCKADDR_MAP -> { $ai -> { 'family' } } ) ) {

                unless( $config -> get( 'graphite.disable_preventive_hostname_resolution' ) ) {

                    my $host = eval{ Socket::inet_ntop(
                        $ai -> { 'family' },
                        ( $code -> ( $ai -> { 'addr' } ) )[ 1 ],
                    ) };

                    warn $@ if $@;

                    if( defined $host ) {

                        if( $ai -> { 'family' } == AF_INET6 ) {

                            $host = "[${host}]";

                        }

                        $uri -> host( $host );

                    } else {

                        next;
                    }
                }

                return $self -> new_graphite( uri => $uri );
            }
        }
    }

    return undef;
}

method new_graphite( URI :uri! ) {

    return Salvation::AnyNotify::Plugin::Graphite::Reader -> new(
        uri => $uri,
    );
}

1;

__END__
