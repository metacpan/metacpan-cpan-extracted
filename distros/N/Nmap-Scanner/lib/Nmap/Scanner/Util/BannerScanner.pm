package Nmap::Scanner::Util::BannerScanner;

=pod

=head2 NAME

BannerScanner - base class for performing banner scans [DEPRECATED] 

=cut
use IO::Socket;

use Nmap::Scanner::Scanner;
use strict;
use vars qw(@ISA);

@ISA = qw(Nmap::Scanner::Scanner);

sub new {
     my $class = shift;
     my $self = $class->SUPER::new();
     return bless $self, $class;
}

=pod

=head2 regex()

Regular expression to use to match the banner in the remote
system output.

=cut

sub regex {
    (defined $_[1]) ? ($_[0]->{REGEX} = $_[1]) : return $_[0]->{REGEX};
}

=pod

=head2 send_on_connect()

Protocol string to send once a connection to the remote host has been
successfully made.

=cut

sub send_on_connect {
    (defined $_[1]) ? ($_[0]->{SEND} = $_[1]) : return $_[0]->{SEND};
}

=pod

=head2 register_scan_complete_event()

Pass in a reference to a function that will be called when the banner is
found.  The function will receive three arguments:  a reference to self
(object reference of caller), a reference to an Host object representing 
the remote host, and the banner as captured.

=cut

sub register_banner_found_event {
    (defined $_[1]) ? ($_[0]->{CALLBACK} = $_[1]) : return $_[0]->{CALLBACK};
}

sub scan {

    $_[0]->tcp_syn_scan();
    $_[0]->register_scan_complete_event(\&banner);
    $_[0]->SUPER::scan();

}

sub banner {
    my $self = shift;
    my $host = shift;
    my $port = $host->get_port_list->get_next();
    my $banner = get_banner(
        $host, $port, $self->{REGEX}, $self->{SEND}
    );

    &{$self->{CALLBACK}}($self, $host, $banner)
        if (ref($self->{'CALLBACK'}) eq 'CODE');
}

sub get_banner {

    my $host  = (shift->addresses())[0]->addr();
    my $port  = shift || return;
    my $regex = shift || '.';
    my $send  = shift;

    $port  = $port->portid();

    my $server = "";
    local($_);

    my $sock = new IO::Socket::INET(
        PeerAddr => "$host:$port",
        Timeout  => 30
    );

    if (! $sock) {
        print "$host: can't connect: $!\n";
        return "";
    }

    if ($send) {
        $sock->print($send);
    }

    while (<$sock>) {
        if (/$regex/) {
            $server = $1;
            $server =~ s/\r\n//g;
            $sock->close();
            last;
        }
    }

    $sock->close();
    undef $sock;

    return $server;

}

1;
