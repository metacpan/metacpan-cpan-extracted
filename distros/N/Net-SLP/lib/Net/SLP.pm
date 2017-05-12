# SLP.pm
#
# Main module Net::SLP
# Author Mike McCauley (mikem@airspayce.com)
# Copyright (C) Mike McCauley
# $Id: SLP.pm,v 1.3 2007/06/20 22:46:15 mikem Exp mikem $
package Net::SLP;

use 5.00503;
use strict;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD);
@ISA = qw(Exporter
	DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Net::SLP ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
%EXPORT_TAGS = ( 'all' => [ qw(
	SLP_AUTHENTICATION_ABSENT
	SLP_AUTHENTICATION_FAILED
	SLP_BUFFER_OVERFLOW
	SLP_FALSE
	SLP_HANDLE_IN_USE
	SLP_INTERNAL_SYSTEM_ERROR
	SLP_INVALID_REGISTRATION
	SLP_INVALID_UPDATE
	SLP_LANGUAGE_NOT_SUPPORTED
	SLP_LAST_CALL
	SLP_LIFETIME_DEFAULT
	SLP_LIFETIME_MAXIMUM
	SLP_MEMORY_ALLOC_FAILED
	SLP_NETWORK_ERROR
	SLP_NETWORK_INIT_FAILED
	SLP_NETWORK_TIMED_OUT
	SLP_NOT_IMPLEMENTED
	SLP_OK
	SLP_PARAMETER_BAD
	SLP_PARSE_ERROR
	SLP_REFRESH_REJECTED
	SLP_SCOPE_NOT_SUPPORTED
	SLP_TRUE
	SLP_TYPE_ERROR
) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw(
	SLP_AUTHENTICATION_ABSENT
	SLP_AUTHENTICATION_FAILED
	SLP_BUFFER_OVERFLOW
	SLP_FALSE
	SLP_HANDLE_IN_USE
	SLP_INTERNAL_SYSTEM_ERROR
	SLP_INVALID_REGISTRATION
	SLP_INVALID_UPDATE
	SLP_LANGUAGE_NOT_SUPPORTED
	SLP_LAST_CALL
	SLP_LIFETIME_DEFAULT
	SLP_LIFETIME_MAXIMUM
	SLP_MEMORY_ALLOC_FAILED
	SLP_NETWORK_ERROR
	SLP_NETWORK_INIT_FAILED
	SLP_NETWORK_TIMED_OUT
	SLP_NOT_IMPLEMENTED
	SLP_OK
	SLP_PARAMETER_BAD
	SLP_PARSE_ERROR
	SLP_REFRESH_REJECTED
	SLP_SCOPE_NOT_SUPPORTED
	SLP_TRUE
	SLP_TYPE_ERROR
);

$VERSION = '1.5';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Net::SLP::constant not defined" if $constname eq 'constant';
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

bootstrap Net::SLP $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Net::SLP - Perl extension for accessing the Service Location Protocol (SLP) API.
SLP can be used to discover the location of services

=head1 SYNOPSIS

use Net::SLP;
my $handle;
Net::SLP::SLPOpen('', 0, $handle);
Net::SLP::SLPReg($handle, 
		    'service:mytestservice.x://zulu.airspayce.com:9048', # URL
		    Net::SLP::SLP_LIFETIME_MAXIMUM,                # lifetime
		    '',                                             # srvtype (ignored)
		    '(attr1=val1),(attr2=val2),(attr3=val3)',          # attrs
		    1,                             # Register. SLP does not support reregister.
		    \&regcallback)
Net::SLP::SLPFindSrvs($handle, 'mytestservice.x', '', '', \&urlcallback);
Net::SLP::SLPClose($handle);

# Called when a service is registered or deregisted with 
# SLPReg(), SLPDeReg() and SLPDelAttrs() functions.
sub regcallback
{
    my ($errcode) = @_;
}
# Called when a service URL is available from SLPFindSrvs
# This callback returns SLP_TRUE if it wishes to be called again if there is more
# data, else SLP_FALSE
# If $errcode == SLP_LAST_CALL, then there is no more data
sub urlcallback
{
    my ($srvurl, $lifetime, $errcode) = @_;
    return Net::SLP::SLP_TRUE;
}

=head1 DESCRIPTION

SLP is the Service Location Protocol, a protocol fpor discovering the location 
and attributes of servers for some required service. There is a standard C API for SLP, 
and this module is a wrapper around that API. The API is described in RFC2614, see which 
for detailed API usage. All RFC2614 functions are implmeneted except for SLPParseSrvURL()
and SLPFree().

=head2 EXPORT

None by default.

=head2 Exportable constants

  SLP_AUTHENTICATION_ABSENT
  SLP_AUTHENTICATION_FAILED
  SLP_BUFFER_OVERFLOW
  SLP_FALSE
  SLP_HANDLE_IN_USE
  SLP_INTERNAL_SYSTEM_ERROR
  SLP_INVALID_REGISTRATION
  SLP_INVALID_UPDATE
  SLP_LANGUAGE_NOT_SUPPORTED
  SLP_LAST_CALL
  SLP_LIFETIME_DEFAULT
  SLP_LIFETIME_MAXIMUM
  SLP_MEMORY_ALLOC_FAILED
  SLP_NETWORK_ERROR
  SLP_NETWORK_INIT_FAILED
  SLP_NETWORK_TIMED_OUT
  SLP_NOT_IMPLEMENTED
  SLP_OK
  SLP_PARAMETER_BAD
  SLP_PARSE_ERROR
  SLP_REFRESH_REJECTED
  SLP_SCOPE_NOT_SUPPORTED
  SLP_TRUE
  SLP_TYPE_ERROR



=head1 SEE ALSO

Openslp Programmer Guide http://www.openslp.org
RFC2608 (SLPv2)
RFC2614 (SLP API)

=head1 AUTHOR

Mike McCauley, E<lt>mikem@airspayce.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Mike McCauley

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
