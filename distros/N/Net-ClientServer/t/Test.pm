package t::Test;

use strict;
use warnings;

use IO::Socket::INET;

sub find_port {
    my $self = shift;

    my $start_port = 20200;
    my @found;
    for my $port ( $start_port .. ( $start_port + 99 ) ) {
        my $socket = IO::Socket::INET->new(
            PeerAddr => 'localhost',
            PeerPort => $port,
            Timeout  => 1,
            Proto => 'tcp'
        );
        push @found, $port unless defined $socket;#
        last if 1 == @found;
    }
    return unless @found;
    return wantarray ? @found : $found[0];
}

sub can_fork {
    my $self = shift;
    
    my $fork = 0;
    eval {
        my $pid = fork;
        return unless defined $pid;
        exit unless $pid;
        $fork = 1;
    };

    return $fork;
}

1;
