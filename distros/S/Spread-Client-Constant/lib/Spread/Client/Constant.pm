package Spread::Client::Constant;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Spread::Client::Constant ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	ACCEPT_SESSION
	AGREED_MESS
	BUFFER_TOO_SHORT
	CAUSAL_MESS
	CAUSED_BY_DISCONNECT
	CAUSED_BY_JOIN
	CAUSED_BY_LEAVE
	CAUSED_BY_NETWORK
	CONNECTION_CLOSED
	COULD_NOT_CONNECT
	DEFAULT_SPREAD_PORT
	DROP_RECV
	ENDIAN_RESERVED
	FIFO_MESS
	GROUPS_TOO_SHORT
	HIGH_PRIORITY
	ILLEGAL_GROUP
	ILLEGAL_MESSAGE
	ILLEGAL_SERVICE
	ILLEGAL_SESSION
	ILLEGAL_SPREAD
	LOW_PRIORITY
	MAX_CLIENT_SCATTER_ELEMENTS
	MAX_GROUP_NAME
	MAX_PRIVATE_NAME
	MAX_PROC_NAME
	MEDIUM_PRIORITY
	MEMBERSHIP_MESS
	MESSAGE_TOO_LONG
	NET_ERROR_ON_SESSION
	REGULAR_MESS
	REG_MEMB_MESS
	REJECT_AUTH
	REJECT_ILLEGAL_NAME
	REJECT_MESS
	REJECT_NOT_UNIQUE
	REJECT_NO_NAME
	REJECT_QUOTA
	REJECT_VERSION
	RELIABLE_MESS
	RESERVED
	SAFE_MESS
	SELF_DISCARD
	SPREAD_VERSION
	TRANSITION_MESS
	UNRELIABLE_MESS
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT;

our $VERSION = '0.02';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Spread::Client::Constant::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Spread::Client::Constant', $VERSION);

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Spread::Client::Constant - Spread::Client constants PM.

=head1 SYNOPSIS

  use Spread::Client::Constant ':all';

=head1 DESCRIPTION

Constants used by Spread::Client.  These are generated from the Spread Toolkit header file.  I'm breaking
these out since I am considering breaking out the actual message creation module L<Spread::Client::Frame>
from the main Spread::Client distro incase someone wants to build their own client or stripped down client
for a specific use case.


=head1 EXPORT

None by default.  Use the ':all' tag for everything below, or export them individually.

=head2 Exportable constants

  ACCEPT_SESSION
  AGREED_MESS
  BUFFER_TOO_SHORT
  CAUSAL_MESS
  CAUSED_BY_DISCONNECT
  CAUSED_BY_JOIN
  CAUSED_BY_LEAVE
  CAUSED_BY_NETWORK
  CONNECTION_CLOSED
  COULD_NOT_CONNECT
  DEFAULT_SPREAD_PORT
  DROP_RECV
  ENDIAN_RESERVED
  FIFO_MESS
  GROUPS_TOO_SHORT
  HIGH_PRIORITY
  ILLEGAL_GROUP
  ILLEGAL_MESSAGE
  ILLEGAL_SERVICE
  ILLEGAL_SESSION
  ILLEGAL_SPREAD
  LOW_PRIORITY
  MAX_CLIENT_SCATTER_ELEMENTS
  MAX_GROUP_NAME
  MAX_PRIVATE_NAME
  MAX_PROC_NAME
  MEDIUM_PRIORITY
  MEMBERSHIP_MESS
  MESSAGE_TOO_LONG
  NET_ERROR_ON_SESSION
  REGULAR_MESS
  REG_MEMB_MESS
  REJECT_AUTH
  REJECT_ILLEGAL_NAME
  REJECT_MESS
  REJECT_NOT_UNIQUE
  REJECT_NO_NAME
  REJECT_QUOTA
  REJECT_VERSION
  RELIABLE_MESS
  RESERVED
  SAFE_MESS
  SELF_DISCARD
  SPREAD_VERSION
  TRANSITION_MESS
  UNRELIABLE_MESS


=head1 SEE ALSO

Spread Toolkit L<http://www.spread.org/>

=head1 AUTHOR

Marlon Bailey, E<lt>mbailey@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Marlon Bailey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
