# Net::ICAP::Common -- Common ICAP Constants
#
# (c) 2012, Arthur Corliss <corliss@digitalmages.com>
#
# $Revision: 0.04 $
#
#    This software is licensed under the same terms as Perl, itself.
#    Please see http://dev.perl.org/licenses/ for more information.
#
#####################################################################

#####################################################################
#
# Environment definitions
#
#####################################################################

package Net::ICAP::Common;

use 5.008003;

use strict;
use warnings;
use vars qw(@EXPORT @EXPORT_OK %EXPORT_TAGS @ISA $VERSION);
use Exporter;

($VERSION) = ( q$Revision: 0.04 $ =~ /(\d+(?:\.(\d+))+)/s );

@ISA = qw(Exporter);

my @debug = qw(ICAPDEBUG1 ICAPDEBUG2 ICAPDEBUG3 ICAPDEBUG4);
my @req   = qw(ICAP_REQMOD ICAP_RESPMOD ICAP_OPTIONS);
my @resp  = qw(ICAP_CONTINUE ICAP_OK ICAP_NO_MOD_NEEDED ICAP_BAD_REQUEST
    ICAP_UNAUTHORIZED ICAP_FORBIDDEN ICAP_SERVICE_NOT_FOUND
    ICAP_METHOD_NOT_ALLOWED ICAP_AUTH_REQUIRED ICAP_REQUEST_TIMEOUT
    ICAP_LENGTH_REQUIRED ICAP_URI_TOO_LARGE
    ICAP_SERVER_ERROR ICAP_METHOD_NOT_IMPLEMENTED ICAP_BAD_GATEWAY
    ICAP_SERVICE_OVERLOADED ICAP_GATEWAY_TIMEOUT ICAP_VERSION_NOT_SUPPORTED);

@EXPORT = qw(ICAP_VERSION ICAP_REQ_HDR ICAP_RES_HDR ICAP_REQ_BODY
    ICAP_RES_BODY ICAP_OPT_BODY ICAP_NULL_BODY ICAP_DEF_PORT);
@EXPORT_OK = ( @EXPORT, @debug, @req, @resp );
%EXPORT_TAGS = (
    all   => [@EXPORT_OK],
    std   => [@EXPORT],
    debug => [@debug],
    req   => [@req],
    resp  => [@resp],
    );

use constant ICAPDEBUG1 => 5;
use constant ICAPDEBUG2 => 6;
use constant ICAPDEBUG3 => 7;
use constant ICAPDEBUG4 => 8;

use constant ICAP_DEF_PORT => 1344;
use constant ICAP_VERSION  => 'ICAP/1.0';

use constant ICAP_REQ_HDR   => 'req-hdr';
use constant ICAP_RES_HDR   => 'res-hdr';
use constant ICAP_REQ_BODY  => 'req-body';
use constant ICAP_RES_BODY  => 'res-body';
use constant ICAP_OPT_BODY  => 'opt-body';
use constant ICAP_NULL_BODY => 'null-body';

use constant ICAP_REQMOD  => 'REQMOD';
use constant ICAP_RESPMOD => 'RESPMOD';
use constant ICAP_OPTIONS => 'OPTIONS';

use constant ICAP_CONTINUE               => 100;
use constant ICAP_OK                     => 200;
use constant ICAP_NO_MOD_NEEDED          => 204;
use constant ICAP_BAD_REQUEST            => 400;
use constant ICAP_UNAUTHORIZED           => 401;
use constant ICAP_FORBIDDEN              => 403;
use constant ICAP_SERVICE_NOT_FOUND      => 404;
use constant ICAP_METHOD_NOT_ALLOWED     => 405;
use constant ICAP_AUTH_REQUIRED          => 407;
use constant ICAP_REQUEST_TIMEOUT        => 408;
use constant ICAP_LENGTH_REQUIRED        => 411;
use constant ICAP_URI_TOO_LARGE          => 414;
use constant ICAP_BAD_COMPOSTION         => 418;
use constant ICAP_SERVER_ERROR           => 500;
use constant ICAP_METHOD_NOT_IMPLEMENTED => 501;
use constant ICAP_BAD_GATEWAY            => 502;
use constant ICAP_SERVICE_OVERLOADED     => 503;
use constant ICAP_GATEWAY_TIMEOUT        => 504;
use constant ICAP_VERSION_NOT_SUPPORTED  => 505;

#####################################################################
#
# Net::ICAP::Common code follows
#
#####################################################################

1;

__END__

=head1 NAME

Net::ICAP::Common - Common ICAP Constants

=head1 VERSION

$Id: lib/Net/ICAP/Common.pm, 0.04 2017/04/12 15:54:19 acorliss Exp $

=head1 SYNOPSIS

    use Net::ICAP::Common qw(:all);

=head1 DESCRIPTION

This module provides commonly used constants.  You can selective import the
following sets of constants:

=over

=item o B<:all> - All constants

=item o B<:std> - Basic ICAP constants common to all message types

=item o B<:req> - ICAP constants specific to requests

=item o B<:resp> - ICAP constants specific to responses

=back

=head1 CONSTANTS

=head2 :std

The following constants are used (primarily) internally for all ICAP message
types.

=head3 ICAP_DEF_PORT

  1344

The default TCP port used by ICAP.

=head3 ICAP_VERSION

  ICAP/1.0

The ICAP protocol version string.

=head3 ICAP_REQ_HDR

  req-hdr

The HTTP request header entity string as used in the Encapsulated header.

=head3 ICAP_RES_HDR

  res-hdr

The HTTP response header entity string as used in the Encapsulated header.

=head3 ICAP_REQ_BODY

  req-body

The HTTP request body entity string as used in the Encapsulated header.

=head3 ICAP_RES_BODY

  res-body

The HTTP response body entity string as used in the Encapsulated header.

=head3 ICAP_OPT_BODY

  opt-body

The ICAP options body entity string as used in the Encapsulated header.

=head3 ICAP_NULL_BODY

  null-body

The ICAP null body entity string as used in the Encapsulated header.

=head2 :req

The following constants are used specifically for ICAP Request messages.

=head3 ICAP_REQMOD

  REQMOD

The Request Modification method.

=head3 ICAP_RESPMOD

  RESPMOD

The Response Modification method.

=head3 ICAP_OPTIONS

  OPTIONS

The Options method.

=head2 :resp

The following constants are used specifically for ICAP Response messages.

=head3 ICAP_CONTINUE

  100

The ICAP status code for 'Continue after ICAP Preview' responses.

=head3 ICAP_OK

  200

The ICAP status code for 'OK' responses.

=head3 ICAP_NO_MOD_NEEDED

  204

The ICAP status code for 'No Modifications Needed' responses.

=head3 ICAP_BAD_REQUEST

  400

The ICAP status code for 'Bad Request' responses.

=head3 ICAP_UNAUTHORIZED

  401

The ICAP status code for 'Unauthorized' responses.

=head3 ICAP_FORBIDDEN

  403

The ICAP status code for 'Forbidden' responses.

=head3 ICAP_SERVICE_NOT_FOUND

  404

The ICAP status code for 'ICAP Service Not Found' responses.

=head3 ICAP_METHOD_NOT_ALLOWED

  405

The ICAP status code for 'Method Not Allowed For Service' responses.

=head3 ICAP_AUTH_REQUIRED

  407

The ICAP status code for 'Proxy Authentication Required' responses.

=head3 ICAP_REQUEST_TIMEOUT

  408

The ICAP status code for 'Request Time-out' responses.

=head3 ICAP_LENGTH_REQUIRED

  411

The ICAP status code for 'Length Required' responses.

=head3 ICAP_URI_TOO_LARGE

  414

The ICAP status code for 'Request-URI Too Large' responses.

=head3 ICAP_SERVER_ERROR

  500

The ICAP status code for 'Internal Server Error' responses.

=head3 ICAP_METHOD_NOT_IMPLEMENTED

  501

The ICAP status code for 'Method Not Implemented' responses.

=head3 ICAP_BAD_GATEWAY

  502

The ICAP status code for 'Bad Gateway' responses.

=head3 ICAP_SERVICE_OVERLOADED

  503

The ICAP status code for 'Service Overloaded' responses.

=head3 ICAP_GATEWAY_TIMEOUT

  504

The ICAP status code for 'Gateway Time-out' responses.

=head3 ICAP_VERSION_NOT_SUPPORTED

  505

The ICAP status code for 'ICAP Version Not Supported' responses.

=head1 DEPENDENCIES

None.

=head1 BUGS AND LIMITATIONS 

It is very likely that there are additional status codes in use in the wild
that are not included here, including the HTTP status codes that also apply to
ICAP.

=head1 AUTHOR 

Arthur Corliss (corliss@digitalmages.com)

=head1 LICENSE AND COPYRIGHT

This software is licensed under the same terms as Perl, itself. 
Please see http://dev.perl.org/licenses/ for more information.

(c) 2012, Arthur Corliss (corliss@digitalmages.com)

