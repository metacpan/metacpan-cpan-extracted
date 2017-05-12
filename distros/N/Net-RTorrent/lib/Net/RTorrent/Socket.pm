#$Id: Socket.pm 865 2010-10-26 06:45:14Z zag $

package Net::RTorrent::Socket;

use strict;
use warnings;
use RPC::XML;
use RPC::XML::Client;
use IO::Socket::INET;
use IO::Socket::UNIX;
use RPC::XML::Parser;
use Carp;
use 5.005;

=head1 NAME

Net::RTorrent::Socket - Direct connect to rtorrent via scgi proto

=head1 SYNOPSIS

  my $scli1 = new Net::RTorrent::Socket:: 'localhost:5000';
  my $req = RPC::XML::request->new('get_memory_usage');
  my $res = $scli3->send_request($req);
  print $res->value


=head1 ABSTRACT
 
Perl interface to rtorrent via scgi

=head1 DESCRIPTION

Net::RTorrent::Socket - Direct connect to rtorrent via scgi proto

=cut

our @ISA     = qw();
our $VERSION = '0.06';

sub new {
    my $class = shift;
    $class = ref $class if ref $class;
    my $self = bless( {}, $class );
    if (@_) {
        my $rpc_addr = shift;
        $self->{addr} = $rpc_addr;
    }
    else {
        carp "need xmlrpc server URL";
        return;
    }
    return $self;
}

sub _create_socket {
    my $self   = shift;
    my $addr   = shift || $self->{addr};
    my $type   = $addr =~ m%/% ? "IO::Socket::UNIX" : "IO::Socket::INET";
    my $socket = $type->new( $addr );
    my $old_fh = select($socket);
    $| = 1;
    select($old_fh);
    return $socket

}

sub send_request {
    my ( $self, $req, @args ) = @_;

    if ( !UNIVERSAL::isa( $req, 'RPC::XML::request' ) ) {

        # Assume that $req is the name of the routine to be called
        $req = RPC::XML::request->new( $req, @args );
        return "Error creating RPC::XML::request object: $RPC::XML::ERROR"
          unless ($req);    # $RPC::XML::ERROR is already set
    }

    # get socket
    my $socket = $self->_create_socket( $self->{addr} );
    my $len  = $req->length;
    my $oheaders =
        "CONTENT_LENGTH\0$len\0" 
      . "SCGI\0" . '1' . "\0"
      . "REQUEST_METHOD\0POST\0";
    print $socket length($oheaders) . ":" . $oheaders . "," . $req->as_string;
    my $ans = '';
    while (<$socket>) {
        $ans .= $_;
    }
    $socket->close;

    my ( $header, $xml ) = split( /\n\s?\n/, $ans );
    my $p = RPC::XML::Parser->new();
    my $value;

    eval { $value = $p->parse($xml) };
    if ($@) {
        return $@
    }
    $value->value;
}
1;
