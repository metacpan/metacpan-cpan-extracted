# -*- perl -*-
#
#  Net::Server::Proto::UNIXDGRAM - Net::Server Protocol module
#
#  $Id$
#
#  Copyright (C) 2001-2012
#
#    Paul Seamons
#    paul@seamons.com
#    http://seamons.com/
#
#  This package may be distributed under the terms of either the
#  GNU General Public License
#    or the
#  Perl Artistic License
#
#  All rights reserved.
#
################################################################

package Net::Server::Proto::UNIXDGRAM;

use strict;
use base qw(Net::Server::Proto::UNIX);
use Socket qw(SOCK_DGRAM);

my @udp_args = qw(
    udp_recv_len
    udp_recv_flags
    udp_broadcast
); # we do broadcast just for cacheing parallelism with UDP.pm

sub NS_proto { 'UNIXDGRAM' }
sub NS_recv_len   { my $sock = shift; ${*$sock}{'NS_recv_len'}   = shift if @_; return ${*$sock}{'NS_recv_len'}   }
sub NS_recv_flags { my $sock = shift; ${*$sock}{'NS_recv_flags'} = shift if @_; return ${*$sock}{'NS_recv_flags'} }
sub NS_unix_type  { 'SOCK_DGRAM' }

sub object {
    my ($class, $info, $server) = @_;

    my $udp = $server->{'server'}->{'udp_args'} ||= do {
        my %temp = map {$_ => undef} @udp_args;
        $server->configure({map {$_ => \$temp{$_}} @udp_args});
        \%temp;
    };

    my $len = defined($info->{'udp_recv_len'}) ? $info->{'udp_recv_len'}
            : defined($udp->{'udp_recv_len'})  ? $udp->{'udp_recv_len'}
            : 4096;
    $len = ($len =~ /^(\d+)$/) ? $1 : 4096;

    my $flg = defined($info->{'udp_recv_flags'}) ? $info->{'udp_recv_flags'}
            : defined($udp->{'udp_recv_flags'})  ? $udp->{'udp_recv_flags'}
            : 0;
    $flg = ($flg =~ /^(\d+)$/) ? $1 : 0;

    my $sock = $class->SUPER::new();
    my $port = $info->{'port'} =~ m{^ ([\w\.\-\*\/]+) $ }x ? $1 : $server->fatal("Insecure filename");
    $sock->NS_port($port);
    $sock->NS_recv_len($len);
    $sock->NS_recv_flags($flg);
    return $sock;
}

sub connect {
    my ($sock, $server) = @_;
    my $path = $sock->NS_port;
    $server->fatal("Can't connect to UNIXDGRAM socket at file $path [$!]") if -e $path && ! unlink $path;

    $sock->SUPER::configure({
        Local  => $path,
        Type   => SOCK_DGRAM,
    }) or $server->fatal("Can't connect to UNIXDGRAM socket at file $path [$!]");
}

1;

__END__

=head1 NAME

Net::Server::Proto::UNIXDGRAM - Net::Server UNIXDGRAM protocol.

=head1 SYNOPSIS

See L<Net::Server::Proto>.

=head1 DESCRIPTION

Protocol module for Net::Server.  This module implements the UNIX
SOCK_DGRAM socket type.  See L<Net::Server::Proto>.

Any sockets created during startup will be chown'ed to the user and
group specified in the starup arguments.

=head1 PARAMETERS

The following paramaters may be specified in addition to normal
command line parameters for a Net::Server.  See L<Net::Server> for
more information on reading arguments.

=over 4

=item udp_recv_len

Specifies the number of bytes to read from the SOCK_DGRAM connection
handle.  Data will be read into $self->{'server'}->{'udp_data'}.
Default is 4096.  See L<IO::Socket::INET> and L<recv>.

=item udp_recv_flags

See L<recv>.  Default is 0.

=back

=head1 QUICK PARAMETER LIST

  Key               Value                    Default

  ## UNIXDGRAM socket parameters
  udp_recv_len      \d+                      4096
  udp_recv_flags    \d+                      0

=head1 LICENCE

Distributed under the same terms as Net::Server

=cut
