##############################################################################
#
#  Net::Tools::Socket::Err common socket, protocols and pair error codes
#  Copyright (c) 2026 Vladi Belperchinov-Shabanski "Cade"
#        <cade@noxrun.com>
#  http://cade.noxrun.com/
#
#  GPL
#
##############################################################################
#
#  one error state shared by all Net::Tools::Socket* modules:
#
#    $SOCK_ERR      last error code: negative SOCK_E_* constant, or positive
#                   errno value if a system call failed, undef if not set
#                   (no error). errno values are always positive, so they
#                   never collide with SOCK_E_* codes.
#    $SOCK_ERRSTR   last error text, undef if not set
#    sock_err_name() name of $SOCK_ERR: 'SOCK_E_EOF', 'SOCK_E_TIMEOUT', etc.
#                   or errno name: 'EPIPE', 'EBADF', etc.
#    %SOCK_ERRSTR   SOCK_E_* code => text map, locked (read only)
#
#  socket functions clear the state on entry and set it on error:
#
#    sock_err_clear();
#    ...
#    return sock_err( SOCK_E_EOF, undef ) if ...;
#    return sock_err( SOCK_E_PROTO, undef, "bad type" ) if ...; # extra text
#    return sock_err_sys( undef ) unless defined sysread( ... );
#
#  the optional third argument of sock_err() is extra text appended to
#  $SOCK_ERRSTR after ": " (SOCK_E_* codes only, not errno values).
#
#  the state describes only the last call, read it right after the call.
#
##############################################################################
package Net::Tools::Socket::Err;
use strict;
use Exporter;
use Hash::Util qw( lock_hash );
use Errno;

our $VERSION = '1.60';

our @ISA    = qw( Exporter );
our @EXPORT = qw(
                  $SOCK_ERR
                  $SOCK_ERRSTR
                  %SOCK_ERRSTR

                  sock_err
                  sock_err_sys
                  sock_err_clear
                  sock_err_name

                  SOCK_E_AGAIN
                  SOCK_E_EOF
                  SOCK_E_TOOBIG
                  SOCK_E_EMPTY
                  SOCK_E_MSGLEN
                  SOCK_E_SHORT
                  SOCK_E_TIMEOUT
                  SOCK_E_PROTO
                  SOCK_E_SYS
                  SOCK_E_INVAL
                );

use constant
  {
  SOCK_E_AGAIN   =>  -1, # nothing to read or peer's queue full, retry
  SOCK_E_EOF     =>  -2, # peer closed
  SOCK_E_TOOBIG  =>  -3, # message larger than allowed
  SOCK_E_EMPTY   =>  -4, # empty or undef message
  SOCK_E_MSGLEN  =>  -5, # invalid or unreadable message length
  SOCK_E_SHORT   =>  -6, # short read or write below requested count
  SOCK_E_TIMEOUT =>  -7, # timed out
  SOCK_E_PROTO   =>  -8, # unknown or forbidden protocol, invalid data
  SOCK_E_SYS     =>  -9, # system call failed but $! is not set
  SOCK_E_INVAL   => -10, # invalid argument or data (wide characters, etc.)
  };

our $SOCK_ERR;
our $SOCK_ERRSTR;

our %SOCK_ERRSTR = (
                   SOCK_E_AGAIN()   => 'try again',
                   SOCK_E_EOF()     => 'end of file, peer closed',
                   SOCK_E_TOOBIG()  => 'message too big',
                   SOCK_E_EMPTY()   => 'empty message',
                   SOCK_E_MSGLEN()  => 'invalid message length',
                   SOCK_E_SHORT()   => 'short read or write below requested count',
                   SOCK_E_TIMEOUT() => 'timeout',
                   SOCK_E_PROTO()   => 'protocol error',
                   SOCK_E_SYS()     => 'system error, unknown errno',
                   SOCK_E_INVAL()   => 'invalid argument',
                   );

lock_hash( %SOCK_ERRSTR );

# constant names, returned by sock_err_name()
my %SOCK_ERRNAME = (
                   SOCK_E_AGAIN()   => 'SOCK_E_AGAIN',
                   SOCK_E_EOF()     => 'SOCK_E_EOF',
                   SOCK_E_TOOBIG()  => 'SOCK_E_TOOBIG',
                   SOCK_E_EMPTY()   => 'SOCK_E_EMPTY',
                   SOCK_E_MSGLEN()  => 'SOCK_E_MSGLEN',
                   SOCK_E_SHORT()   => 'SOCK_E_SHORT',
                   SOCK_E_TIMEOUT() => 'SOCK_E_TIMEOUT',
                   SOCK_E_PROTO()   => 'SOCK_E_PROTO',
                   SOCK_E_SYS()     => 'SOCK_E_SYS',
                   SOCK_E_INVAL()   => 'SOCK_E_INVAL',
                   );

# errno value => name ('EPIPE', etc.), first name in sort order wins for
# aliases (EAGAIN/EWOULDBLOCK)
my %ERRNO_NAME;
for my $name ( sort @Errno::EXPORT_OK )
  {
  my $sub = Errno->can( $name ) or next;
  my $val = eval { $sub->() };
  $ERRNO_NAME{ $val } //= $name if $val;
  }

# sets error state to the given code and returns the second argument,
# so it can be used as: return sock_err( SOCK_E_EOF, undef );
# positive code is errno value, its text is taken from the system.
# optional third argument is extra text appended after ": " to the text of
# a negative (SOCK_E_*) code, ignored for errno values
sub sock_err
{
  my $code = shift;
  my $ret  = shift;
  my $xtra = shift;

  $SOCK_ERR = $code;
  if( $code > 0 )
    {
    local $! = $code;
    $SOCK_ERRSTR = "$!";
    }
  else
    {
    # locked hash dies on access to unknown key, so check first
    $SOCK_ERRSTR = exists $SOCK_ERRSTR{ $code } ? $SOCK_ERRSTR{ $code } : "unknown error code [$code]";
    $SOCK_ERRSTR .= ': ' . $xtra if $xtra;
    }

  return $ret;
}

# sets error state to current errno ($!) after failed system call and returns
# the argument: return sock_err_sys( undef ) unless defined $res;
# SOCK_E_SYS if $! is not set. must be called right after the failed call.
sub sock_err_sys
{
  my $errno = $! + 0;
  return sock_err( $errno > 0 ? $errno : SOCK_E_SYS, shift );
}

# returns name ('SOCK_E_EOF', 'SOCK_E_TIMEOUT', etc.) of the given code or of
# the current $SOCK_ERR if no code given, errno name ('EPIPE', etc.) for
# positive codes, undef if not set
sub sock_err_name
{
  my $code = @_ ? shift : $SOCK_ERR;
  return undef unless defined $code;
  return $ERRNO_NAME{ $code } || "ERRNO_$code" if $code > 0;
  return exists $SOCK_ERRNAME{ $code } ? $SOCK_ERRNAME{ $code } : 'SOCK_E_UNKNOWN';
}

sub sock_err_clear
{
  $SOCK_ERR    = undef;
  $SOCK_ERRSTR = undef;
  return 1;
}

##############################################################################
1;


=pod

=head1 NAME

Net::Tools::Socket::Err - error codes and error state shared by the Net::Tools::Socket modules

=head1 SYNOPSIS

  use Net::Tools::Socket;
  use Net::Tools::Socket::Err;

  my $data = socket_read_message( $socket, $timeout );
  if( ! defined $data )
    {
    print "error: $SOCK_ERRSTR\n" if defined $SOCK_ERR;
    reconnect() if $SOCK_ERR == SOCK_E_EOF;
    print "name: " . sock_err_name() . "\n"; # 'SOCK_E_EOF', 'EBADF', etc.
    }

=head1 DESCRIPTION

L<Net::Tools::Socket>, L<Net::Tools::Socket::Protocols> and
L<Net::Tools::Socket::Pair> share one error state. Every function of those
modules clears it on entry and sets it when it fails, so it describes the
last call only and must be read right after it.

=head1 VARIABLES

=over 4

=item $SOCK_ERR

The last error code: a negative SOCK_E_* constant, or the positive errno
value when a system call failed, undef when there is no error. errno values
are always positive and SOCK_E_* codes negative, so they never collide.

=item $SOCK_ERRSTR

The text of the last error, undef when there is no error. For errno values
it is the system text (C<"$!">), for SOCK_E_* codes it is taken from
%SOCK_ERRSTR and may be followed by ": " and details, for example the
rejected protocol type.

=item %SOCK_ERRSTR

SOCK_E_* code => text map. It is locked, reading an unknown key or changing
it dies.

=back

=head1 ERROR CODES

  SOCK_E_AGAIN     nothing to read or peer's queue is full, retry
  SOCK_E_EOF       end of file, peer closed
  SOCK_E_TOOBIG    message larger than allowed
  SOCK_E_EMPTY     empty or undef message
  SOCK_E_MSGLEN    invalid or unreadable message length
  SOCK_E_SHORT     short read or write below requested count
  SOCK_E_TIMEOUT   timed out
  SOCK_E_PROTO     unknown or forbidden protocol type, or invalid data
  SOCK_E_SYS       system call failed but $! is not set
  SOCK_E_INVAL     invalid argument or data (wide characters, etc.)

Which codes a function sets is documented with the function.

=head1 FUNCTIONS

These are used by the socket modules to set the state, and by callers to
read it.

=head2 sock_err( $code, $ret, $xtra )

Sets $SOCK_ERR to $code and $SOCK_ERRSTR to its text, then returns $ret, so
it can be used as:

  return sock_err( SOCK_E_EOF, undef ) if ...;

A positive $code is an errno value and its text is the system one, $! is
not changed. An unknown negative $code gets the text
"unknown error code [$code]". $xtra, if given and not empty, is appended to
the text of a negative code after ": ", it is ignored for errno values.

=head2 sock_err_sys( $ret )

Sets the state from the current $! after a failed system call and returns
$ret. If $! is not set, $SOCK_ERR is SOCK_E_SYS. Must be called right after
the failed call, before anything else changes $!.

=head2 sock_err_name( $code )

Returns the name of $code, or of $SOCK_ERR if no $code is given:
'SOCK_E_EOF', 'SOCK_E_TIMEOUT', etc. for SOCK_E_* codes, 'SOCK_E_UNKNOWN'
for an unknown negative code, 'EPIPE', 'EBADF', etc. for errno values
('ERRNO_<value>' if the value has no name), undef if not set.

=head2 sock_err_clear()

Clears $SOCK_ERR and $SOCK_ERRSTR to undef, returns 1.

=head1 EXPORTS

All variables, functions and SOCK_E_* constants are exported by default.

=head1 SEE ALSO

L<Net::Tools::Socket>, L<Net::Tools::Socket::Protocols>,
L<Net::Tools::Socket::Pair>, L<Errno>

=head1 AUTHOR

  Vladi Belperchinov-Shabanski "Cade"
        <cade@noxrun.com>
  http://cade.noxrun.com/

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Vladi Belperchinov-Shabanski "Cade"

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.

=cut
