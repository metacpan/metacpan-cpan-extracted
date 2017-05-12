package Net::ClientServer::Server;

use strict;
use warnings;

use IO::Socket::INET;

sub server_socket {
    my $self = shift;
    my %options = @_;

    my $host = $options{host};
#    $host = 0 unless defined $host; # IPV6?
    my $port = $options{port};

    my @arguments;
    push @arguments, LocalHost => $host if $host;

    my $socket = IO::Socket::INET->new( 
        @arguments,
        LocalPort => $port,
        Proto => 'tcp',
        ReuseAddr => 1,
        Listen => 128,
    ) or
    die "Unable to listen on $host/$port: $!";

    return $socket;
}

sub serve {
    my $self = shift;
    my %options = @_;

    my ( $start, $stop, $serve ) = delete @options{qw/ start stop serve /};

    $start->() if $start;

    my $listen = $self->server_socket( %options );

    if ( $options{fork} ) {

        $SIG{CHLD} = 'IGNORE';

        while( my $client = $listen->accept ) {
            my $pid = fork;
            unless ( defined $pid ) {
                warn "Unable to fork: $!";
                sleep 5;
            }
            if ( $pid ) {
                $client->close;
                next;
            }
            else {
                $SIG{CHLD} = 'DEFAULT';
                $serve->( $client );
                $client->close;
                exit;
            }
        }
    }
    else {
        while( my $client = $listen->accept ) {
            $serve->( $client );
            $client->close;
        }
    }

    $stop->() if $stop;
}

1;
