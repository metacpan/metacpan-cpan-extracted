# ABSTRACT: Server::Starter adapter for Feersum Plack handler
package Plack::Handler::Feersum::SS;
$Plack::Handler::Feersum::SS::VERSION = '0.02';
use strict;
use warnings;
use base 'Plack::Handler::Feersum';
use Feersum;
use Server::Starter 'server_ports';
use Carp 'croak';
use Symbol 'geniosym';
use Fcntl qw'F_GETFL F_SETFL O_NONBLOCK';

# redefining (origins: Feersum::Runner, Plack::Handler::Feersum)
sub _prepare {
    my $self = shift;
    delete $self->{quiet} if delete $self->{verbose};
    my %ports = %{server_ports()};
    croak "Feersum doesn't support none/multiple listen directives yet" unless %ports == 1;
    my ($port, $fd) = each %ports;
    open(my $sock = geniosym, "<&=", $fd) || croak $!;
    my $flags = fcntl($sock, F_GETFL, 0) or croak $!;
    fcntl($sock, F_SETFL, $flags | O_NONBLOCK) || croak $!;
    print "Feersum [$$] listening on $port fd=$fd\n" unless $self->{quiet};
    $self->{sock} = $sock;
    my $f = $self->{endjinn} = Feersum->endjinn;
    $f->use_socket($sock);
    if ($self->{options}) {
        $self->{pre_fork} = delete $self->{options}{pre_fork};
    }
    $self->{server_ready}->($self) if $self->{server_ready};
    return;
}

1;
