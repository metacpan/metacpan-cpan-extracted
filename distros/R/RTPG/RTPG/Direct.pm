#!/usr/bin/perl

use utf8;
package RTPG::Direct;

=head1 NAME

RTPG::Direct - is a driver for L<RTPG>.

=head1 VERSION

0.92

=cut

our $VERSION=0.92;

=head1 SYNOPSIS

 my $r = new RTPG::Direct( url => 'localhost:5000' );
 my $r = new RTPG::Direct( url => '/path/to/rtorrent.socket');

 my $resp = $r->send_request('system.listMethods');
 print ref $resp ? join(', ', @{$resp->value}) : "Error: $resp";

=head1 DESCRIPTION

The module uses the L<IO::Socket::UNIX> or the L<IO::Socket::INET>
modules for making connection.

The returned data are recognizing with help of the L<RPC::XML::ParserFactory>.

The method B<send_request> works just like the L<RPC::XML::Client>'s
B<send_request> method.

=head1 AUTHORS

Copyright (C) 2008 Dmitry E. Oboukhov <unera@debian.org>,

Copyright (C) 2008 Roman V. Nikolaev <rshadow@rambler.ru>

=head1 LICENSE

This program is free software: you can redistribute  it  and/or  modify  it
under the terms of the GNU General Public License as published by the  Free
Software Foundation, either version 3 of the License, or (at  your  option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even  the  implied  warranty  of  MERCHANTABILITY  or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public  License  for
more details.

You should have received a copy of the GNU  General  Public  License  along
with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut


use Carp;
use RPC::XML;
use RPC::XML::ParserFactory;
use XML::Parser;
use RPC::XML::Client;
use Encode qw(decode encode);

sub new
{
    my $inv   = shift;
    my $class = ref($inv) || $inv;
    my %opts  = @_;

    for ( keys %opts ) {
        croak "Unknown option name: $_" unless /^(url)$/;
    }
    return bless \%opts, $class;
}

sub _connect_to
{
    my $self = shift;
    my $c;
    if ( $self->{url} =~ m{ ^/ }x ) {
        require IO::Socket::UNIX;
        $c = IO::Socket::UNIX->new( Peer => $self->{url} );
    } else {
        require IO::Socket::INET;
        $c = IO::Socket::INET->new( PeerAddr => $self->{url} );
    }
    $self->{connect_error} = decode utf8 => $! unless $c;
    return $c;
}

sub send_request
{
    my ( $self, $command, @args ) = @_;

    my $request = RPC::XML::request->new( $command, @args )->as_string;
    my $c = $self->_connect_to;
    return sprintf "Can not connect to %s: %s",
        $self->{url}, $self->{connect_error}
        unless $c;

    my $header = sprintf "CONTENT_LENGTH\0%d\0SCGI\0" . "1\0", length $request;
    my $hl;
    { use bytes; $hl = length $header; }

    print $c "$hl:$header,$request";

    my $response;
    { local $/; $response = <$c> };
    $response = ( split /\n\s?\n/, $response, 2 )[1];
    my $result = RPC::XML::ParserFactory->new()->parse($response);

    return $result->{value} if 'RPC::XML::fault' eq ref $result->{value};
    return $result->{value};
}

1;

=head1 AUTHORS

Copyright (C) 2008 Dmitry E. Oboukhov <unera@debian.org>,

Copyright (C) 2008 Roman V. Nikolaev <rshadow@rambler.ru>

=head1 LICENSE

This program is free software: you can redistribute  it  and/or  modify  it
under the terms of the GNU General Public License as published by the  Free
Software Foundation, either version 3 of the License, or (at  your  option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even  the  implied  warranty  of  MERCHANTABILITY  or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public  License  for
more details.

You should have received a copy of the GNU  General  Public  License  along
with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
