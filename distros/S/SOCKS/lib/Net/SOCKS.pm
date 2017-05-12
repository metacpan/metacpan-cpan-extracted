package Net::SOCKS;

# Copyright (c) 1997-1998 Clinton Wong. All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself. 

use strict;
use vars qw($VERSION @ISA @EXPORT);
use IO::Socket;
use Carp;

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
@EXPORT = qw();

$VERSION = '0.03';

# Status code exporter adapted from HTTP::Status by Gisle Aas.
# Please note - users of this module should not use hard coded numbers
#               in their programs.  Always use the SOCKS_ version of
#               the status code, which are the descriptions below
#               converted to uppercase and _ replacing dash and SPACE.

my %status_code = (
  1  =>   "general SOCKS server failure",        # SOCKS5
  2  =>   "connection not allowed by ruleset",
  3  =>   "network unreachable",
  4  =>   "host unreachable",
  5  =>   "connection refused",
  6  =>   "TTL expired",
  7  =>   "command not supported",
  8  =>   "address type not supported",
  90 =>   "okay",                                # SOCKS4 
  91 =>   "failed",
  92 =>   "no ident",
  93 =>   "user mismatch", 
  100 =>  "incomplete auth",                    # generic
  101 =>  "bad auth",
  102 =>  "server denies auth method",
  202  => "missing SOCKS server net data",
  203  => "missing peer net data",
  204  => "SOCKS server unavailable",
  205  => "timeout",
  206  => "unsupported protocol version",
  207  => "unsupported address type",
  208  => "hostname lookup failure"
);

my $mnemonic_code = '';
my ($code, $message);
while (($code, $message) = each %status_code) {
  # create mnemonic subroutines
  $message =~ tr/a-z \-/A-Z__/;
  $mnemonic_code .= "sub SOCKS_$message () { $code }\t";
  $mnemonic_code .= "push(\@EXPORT, 'SOCKS_$message');\n";
}
eval $mnemonic_code; # only one eval for speed
die if $@;

sub status_message {
  return undef unless exists $status_code{ $_[0] };
  $status_code{ $_[0] };
}

1;
__END__

=head1 NAME

Net::SOCKS - a SOCKS client class

=head1 SYNOPSIS

 Establishing a connection:

 my $sock = new Net::SOCKS(socks_addr => '192.168.1.3',
                socks_port => 1080,
                user_id => 'the_user',
                user_password => 'the_password',
                force_nonanonymous => 1,
                protocol_version => 5);

 # connect to finger port and request finger information for some_user
 my $f= $sock->connect(peer_addr => '192.168.1.3', peer_port => 79);
 print $f "some_user\n";    # example writing to socket
 while (<$f>) { print }     # example reading from socket
 $sock->close();

 Accepting an incoming connection:

 my $sock = new Net::SOCKS(socks_addr => '192.168.1.3',
                socks_port => 1080,
                user_id => 'the_user',
                user_password => 'the_password',
                force_nonanonymous => 1,
                protocol_version => 5);

 my ($ip, $ip_dot_dec, $port) = $sock->bind(peer_addr => "128.10.10.11",
                        peer_port => 9999);

 $f= $sock->accept();
 print $f "Hi!  Type something.\n";    # example writing to socket
 while (<$f>) { print }                # example reading from socket
 $sock->close();


=head1 DESCRIPTION

 my $sock = new Net::SOCKS(socks_addr => '192.168.1.3',
                socks_port => 1080,
                user_id => 'the_user',
                user_password => 'the_password',
                force_nonanonymous => 1,
                protocol_version => 5);

  To connect to a SOCKS server, specify the SOCKS server's
  hostname, port number, SOCKS protocol version, username, and
  password.  Username and password are optional if you plan
  to use a SOCKS server that doesn't require any authentication.
  If you would like to force the connection to be 
  nonanoymous, set the force_nonanonymous parameter.

 my $f= $sock->connect(peer_addr => '192.168.1.3', peer_port => 79);

 To connect to another machine using SOCKS, use the connect method.
 Specify the host and port number as parameters.

 my ($ip, $ip_dot_dec, $port) = $sock->bind(peer_addr => "192.168.1.3",
                        peer_port => 9999);

  If you wanted to accept a connection with SOCKS, specify the host
  and port of the machine you expect a connection from.  Upon
  success, bind() returns the ip address and port number that
  the SOCKS server is listening at on your behalf.

 $f= $sock->accept();

  If a call to bind() returns a success status code SOCKS_OKAY,
  a call to the accept() method will return when the peer host
  connects to the host/port that was returned by the bind() method.
  Upon success, accept() returns SOCKS_OKAY.

 $sock->close();

  Closes the connection.

=head1 SEE ALSO

 RFC 1928, RFC 1929.

=head1 AUTHOR

 Clinton Wong, clintdw@netcom.com

=head1 COPYRIGHT

 Copyright (c) 1997-1998 Clinton Wong. All rights reserved.
 This program is free software; you can redistribute it
 and/or modify it under the same terms as Perl itself.

=cut

# constructor new()

# We don't do any parameter error checking here because the programmer
# should be able to get an object back from new().  A croak
# isn't graceful and returning undef isn't descriptive enough.
# Error checking happens when connect() or bind() calls _validate().
# Error messages are retrieved through status_message() and
# param('status_num').

sub new {
  my $class = shift;

  my $self  = {};
  bless $self, $class;

  ${*self}{status_num} = SOCKS_OKAY;
  $self->_import_args(@_);
  $self;
}

# connect() opens a socket through _request() and sends a command
# code of 1 to the SOCKS server.  It returns a reference to a socket
# upon success or undef upon failure.

sub connect {
  my $self = shift;

  if (${*self}{protocol_version}==4) {
    if ( $self->_request(1, @_) == SOCKS_OKAY ) { return ${*self}{fh} }
  } elsif (${*self}{protocol_version}==5) {
    if ( $self->_request5(1, @_) == SOCKS_OKAY ) { return ${*self}{fh} }
  } else {
    ${*self}{status_num} = SOCKS_UNSUPPORTED_PROTOCOL_VERSION;
  }

  return undef;
}


# bind() opens a socket through _request() and sends a command
# code of 2 to the SOCKS server.  Upon success, it returns
# an array of (32 bit IP address, IP address as dotted decimal,
# port number) where the SOCKS server is listening on the
# client's behalf.  Upon failure, return undef.

sub bind {
  my $self = shift;

  if (${*self}{protocol_version}==4) {
    $self->_request(2, @_);
  } elsif (${*self}{protocol_version}==5) {
    $self->_request5(2, @_);
  } else {
    ${*self}{status_num} = SOCKS_UNSUPPORTED_PROTOCOL_VERSION;
  }

  if  (${*self}{status_num} != SOCKS_OKAY) {
    return undef;
  }

  # if we're working with an IPv4 address
  if (${*self}{protocol_version}==4 || (${*self}{protocol_version}==5
	&& defined ${*self}{addr_type} && ${*self}{addr_type}==1)) {

    # if the listen address is zero, assume it is the same as the socks host
    if (defined ${*self}{listen_addr} && ${*self}{listen_addr} == 0) {
      ${*self}{listen_addr} = ${*self}{socks_addr};
    }

    my $dotted_dec = inet_ntoa( pack ("N", ${*self}{listen_addr} ) );
    if (${*self}{status_num}==SOCKS_OKAY) {
      return (${*self}{listen_addr}, $dotted_dec, ${*self}{listen_port})
    } 
  } else {  # not a 32 bit IPv4 address.  FQDN or IPv6 then.
    if (${*self}{addr_type}==4) {                             # IPv6?
      ${*self}{status_num} = SOCKS_UNSUPPORTED_ADDRESS_TYPE;
      return undef;
    }
    if (${*self}{addr_type}==3) {                             # FQDN?
      my $addr = gethostbyname(${*self}{listen_addr});        # -> 32 bit IPv4
      ${*self}{listen_hostname} = ${*self}{listen_addr};
      if (! defined $addr) {
        ${*self}{status_num}=SOCKS_HOSTNAME_LOOKUP_FAILURE;
	return undef;
      }
	
      my $dotted_dec = inet_ntoa( pack ("N", $addr ) );
      return ($addr, $dotted_dec, ${*self}{listen_port})
    }
  }

  return undef;
}

# Upon success, return a reference to a socket.  Otherwise, return undef.

sub accept {
  my ($self) = @_;

  if (${*self}{protocol_version}==4) {
    if ($self->_get_response() == SOCKS_OKAY ) {  return ${*self}{fh} }
  } elsif (${*self}{protocol_version}==5) {
    $self->_get_resp5();
    if (${*self}{status_num} != SOCKS_OKAY) {return undef}

    if (${*self}{addr_type}==4) {                             # IPv6?
      ${*self}{status_num} = SOCKS_UNSUPPORTED_ADDRESS_TYPE;
      return undef;
    }

    if (${*self}{addr_type}==3) {                             # FQDN?
      my $addr = gethostbyname(${*self}{listen_addr});        # -> 32 bit IPv4
      ${*self}{listen_hostname} = ${*self}{listen_addr};
      if (! defined $addr) {
        ${*self}{status_num}=SOCKS_HOSTNAME_LOOKUP_FAILURE;
	return undef;
      }
      ${*self}{listen_addr}=$addr;              # we expect IPv4 to live there
    }

    return ${*self}{fh}
  } else {
    ${*self}{status_num} = SOCKS_UNSUPPORTED_PROTOCOL_VERSION;
  }

  return undef;
}

sub close {
  my ($self) = @_;
  if (defined ${*self}{fh}) {close(${*self}{fh})}
}

# Validate that destination host/port exists

sub _validate {
  my $self = shift;

  # check the method parameters
  unless (defined ${*self}{socks_addr} && length ${*self}{socks_addr}) {
    return ${*self}{status_num} = SOCKS_MISSING_SOCKS_SERVER_NET_DATA;
  }
  unless (defined ${*self}{socks_port} && ${*self}{socks_port} > 0) {
    return ${*self}{status_num} = SOCKS_MISSING_SOCKS_SERVER_NET_DATA;
  }
  unless (defined ${*self}{peer_addr} && length ${*self}{peer_addr}) {
    return ${*self}{status_num} = SOCKS_MISSING_PEER_NET_DATA;
  }
  unless (defined ${*self}{peer_port} && ${*self}{peer_port} > 0) {
    return ${*self}{status_num} = SOCKS_MISSING_PEER_NET_DATA;
  }
  unless (defined ${*self}{protocol_version} &&
          (${*self}{protocol_version}==4 || ${*self}{protocol_version}==5) ) {
    return ${*self}{status_num} = SOCKS_UNSUPPORTED_PROTOCOL_VERSION;
  }

  if (${*self}{protocol_version}==5 && defined ${*self}{user_id} 
     && length(${*self}{user_id})>0 && (! defined ${*self}{user_password}
     || length(${*self}{user_password}) == 0 ) ) {
    return ${*self}{status_num} = SOCKS_INCOMPLETE_AUTH;
  }

  if ( ! defined ${*self}{user_id} ) {  ${*self}{user_id}='' }

  return ${*self}{status_num} = SOCKS_OKAY;
}

sub _request {

  my $self    = shift;
  my $req_num = shift;
  my $rc;

  $self->_import_args(@_);
  $rc=$self->_validate();

  if ($rc != SOCKS_OKAY) { return ${*self}{status_num} = $rc }

  # connect to the SOCKS server
  $rc=$self->_connect();

  if ($rc==SOCKS_OKAY) {

#fixme - check to make sure peer_addr is dotted decimal or do name
#        resolution on it first

    # send the request
    print  { ${*self}{fh} } pack ('CCn', 4, $req_num, ${*self}{peer_port}) .
	inet_aton(${*self}{peer_addr}) . ${*self}{user_id} . (pack 'x');

    # get server response, returns server response code
    return $self->_get_response();
  }
  return ${*self}{status_num} = $rc;
}

# reads response from server, returns status_code, sets object values

sub _get_response {
  my ($self) = @_;
  my $received = '';

  while ( read(${*self}{fh}, $received, 8) && (length($received) < 8) ) {}

  ( ${*self}{vn},  ${*self}{cd}, ${*self}{listen_port},
    ${*self}{listen_addr} ) = unpack 'CCnN', $received;

  return ${*self}{status_num} = ${*self}{cd};
}

sub _request5 {

  my $self    = shift;
  my $req_num = shift;
  my $rc;

  $self->_import_args(@_);
  $rc=$self->_validate();

  if ($rc != SOCKS_OKAY) { return ${*self}{status_num} = $rc }

  # connect to the SOCKS server
  ${*self}{status_num}=$self->_connect();

  if  (${*self}{status_num} != SOCKS_OKAY) {return ${*self}{status_num}}

  # send method request
  $self->_method_request5();
  if  (${*self}{status_num} != SOCKS_OKAY) {return ${*self}{status_num}}

  # get server method response
  $self->_method_response5();
  if  (${*self}{status_num} != SOCKS_OKAY) {return ${*self}{status_num}}

  
  if ( ${*self}{returned_method} == 2) { # username/password needed
    $self->_user_request5();
    if  (${*self}{status_num} != SOCKS_OKAY) {return ${*self}{status_num}}
    $self->_user_response5();
    if  (${*self}{status_num} != SOCKS_OKAY) {return ${*self}{status_num}}
  }

  my $addr_type;
  my $dest_addr;

  if (${*self}{peer_addr} =~ /[a-z][A-Z]/) {    # FQDN?
    $addr_type=3;
    $dest_addr = length(${*self}{peer_addr}) . ${*self}{peer_addr};
  } else {                                      # nope.  Must be dotted-dec.
    $addr_type = 1;
    $dest_addr = inet_aton(${*self}{peer_addr});
  }

  print  { ${*self}{fh} } pack ('CCCC', 5, $req_num, 0, $addr_type);
  print  { ${*self}{fh} } $dest_addr . pack('n', ${*self}{peer_port});

  $self->_get_resp5();
  return ${*self}{status_num};
}

# reads response from server, returns status_code, sets object values

sub _get_resp5 {
  my ($self) = @_;
  my $received = '';

  while ( read(${*self}{fh}, $received, 4) && (length($received) < 4) ) {}

  ( ${*self}{vn},  ${*self}{cd},  ${*self}{socks_flag}, ${*self}{addr_type})=
  unpack('CCCC', $received);


  if ( ${*self}{addr_type} == 3) {                    # FQDN

    $received = '';
    # get length of hostname (pascal style string)
    while ( read(${*self}{fh}, $received, 1) && (length($received) < 1) ) {}
    my $length = unpack('C', $received);

    $received = '';
    while ( read(${*self}{fh}, $received, $length) && (length($received) <
	    $length) ) {}
    ${*self}{listen_addr} = $received;

  } elsif ( ${*self}{addr_type} == 1) {               # IPv4 32 bit

    $received = '';
    while ( read(${*self}{fh}, $received, 4) && (length($received) < 4) ) {}
     ${*self}{listen_addr}=unpack('N', $received);

  } else {                                            # IPv6, others
    ${*self}{status_num} = SOCKS_UNSUPPORTED_ADDRESS_TYPE;
  }

  $received = '';
  while ( read(${*self}{fh}, $received, 2) && (length($received) < 2) ) {}
  ${*self}{listen_port} = unpack('n', $received);

  if (${*self}{cd} == 0) {
    # convert SOCKS5 success status code into the one SOCKS4 uses
    ${*self}{cd} = SOCKS_OKAY;
  }

  return ${*self}{status_num} = ${*self}{cd};
}

sub _method_request5 {

  my $self    = shift;
  my $method = '';

  # add anonymous to method list if the user didn't specify force_nonanonymous
  if ( !defined ${*self}{force_nonanonymous} ||
       ${*self}{force_nonanonymous}==0) {
    # add anonymous connect to method list
    $method.=pack('C', 0); # anonymous
  }

  if ( defined ${*self}{user_id} && length (${*self}{user_id})>0 ) {
    $method.=pack('C', 2); # user/pass
  }

  if (length($method)==0) {
    return  ${*self}{status_num} = SOCKS_INCOMPLETE_AUTH;
  }

  print { ${*self}{fh} } pack ('CC', 5, length($method)), $method;
  return SOCKS_OKAY;
}

sub _method_response5 {
  my ($self) = @_;
  my $received = '';
  
  while ( read(${*self}{fh}, $received, 2) && (length($received) < 2) ) {}

  my ($ver, $method) = unpack 'CC', $received;
  if ($ver!=5) {return SOCKS_UNSUPPORTED_PROTOCOL_VERSION}
  if ($method==255) {return SOCKS_SERVER_DENIES_AUTH_METHOD}
  ${*self}{returned_method} = $method;
}

# code to send username/password to socks5 server
sub _user_request5 {
  my ($self) = @_;

    # check to make sure the user passed in a user/pass field
    if (! defined ${*self}{user_id} || ! defined ${*self}{user_password} ||
	length(${*self}{user_id}) == 0 ||
	length(${*self}{user_password}) == 0) {
      return ${*self}{status_num} = SOCKS_INCOMPLETE_AUTH;
    }

  print { ${*self}{fh} } pack ('CC', 1, length(${*self}{user_id})),
    ${*self}{user_id}, pack ('C', length(${*self}{user_password})),
    ${*self}{user_password};

  return ${*self}{status_num} = SOCKS_OKAY;
}

sub _user_response5 {
  my ($self) = @_;
  my $received = '';
  
  while ( read(${*self}{fh}, $received, 2) && (length($received) < 2) ) {}

  my ($ver, $status) = unpack 'CC', $received;
  if ($status != 0) {
    return ${*self}{status_num} = SOCKS_BAD_AUTH;
  }
  return ${*self}{status_num} = SOCKS_OKAY;
}

# connect to socks server

sub _connect {
  my ($self) = @_;

  ${*self}{fh} = new IO::Socket::INET (
		   PeerAddr => ${*self}{socks_addr},
		   PeerPort => ${*self}{socks_port},
		   Proto  => 'tcp'
		  ) || return ${*self}{status_num} = SOCKS_FAILED;

  my $old_fh = select(${*self}{fh});
  $|=1;
  select($old_fh);

  return ${*self}{status_num} = SOCKS_OKAY;
}


sub _import_args {
  my $self = shift;
  my (%arg, $key);

  # if a reference was passed, dereference it first
  if (ref($_[0]) eq 'HASH') { %arg = %{$_[0]} } else { %arg = @_ }

  foreach $key (keys %arg) { ${*self}{$key} = $arg{$key} }
}

# get/set an internal variable

# Currently known are:
# socks_addr, socks_port, listen_addr, listen_port,
# peer_addr, peer_port, fh, user_id, vn, cd, status_num.

sub param {
  my ($self, $key, $value) = @_;

  if (! defined $value) {
    # No value given.  We're doing a "get"

    if ( defined ${*self}{$key} ) { return ${*self}{$key} }
    else { return undef }
  }
  
  # Value given.  We're doing a "set"

  ${*self}{$key} = $value;
  return $value;
}

1;

