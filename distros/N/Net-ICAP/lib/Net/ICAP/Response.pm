# Net::ICAP::Response -- Response object for ICAP
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

package Net::ICAP::Response;

use 5.008003;

use strict;
use warnings;
use vars qw($VERSION @ISA @_properties @_methods);
use Class::EHierarchy qw(:all);
use Net::ICAP::Common qw(:std :debug :resp);
use Net::ICAP::Message;
use Paranoid::Debug;

($VERSION) = ( q$Revision: 0.04 $ =~ /(\d+(?:\.(\d+))+)/s );

@ISA = qw(Net::ICAP::Message Class::EHierarchy);

@_properties = (
    [ CEH_RESTR | CEH_SCALAR, '_status' ],
    [   CEH_RESTR | CEH_HASH,
        '_status_text',
        {   100 => 'Continue after ICAP Preview',
            200 => 'OK',
            204 => 'No Modifications Needed',
            400 => 'Bad Request',
            401 => 'Unauthorized',
            403 => 'Forbidden',
            404 => 'ICAP Service Not Found',
            405 => 'Method Not Allowed For Service',
            407 => 'Proxy Authentication Required',
            408 => 'Request Time-out',
            411 => 'Length Required',
            414 => 'Request-URI Too Large',
            418 => 'Bad Composition',
            500 => 'Internal Server Error',
            501 => 'Method Not Implemented',
            502 => 'Bad Gateway',
            503 => 'Service Overloaded',
            504 => 'Gateway Time-out',
            505 => 'ICAP Version Not Supported',
        }
    ],
    );

#####################################################################
#
# Module code follows
#
#####################################################################

sub _initialize ($;@) {

    my $obj  = shift;
    my %args = @_;
    my $rv   = 1;

    pdebug( 'entering w/%s and %s', ICAPDEBUG1, $obj, keys %args );
    pIn();

    # Set internal state if args were passed
    $rv = $obj->status( $args{status} ) if exists $args{status};

    pOut();
    pdebug( 'leaving w/rv: %s', ICAPDEBUG1, $rv );

    return $rv;
}

sub _validHeaders ($) {

    # Purpose:  Returns a list of valid ICAP headers
    # Returns:  Array
    # Usage:    @val = $obj->_validHeaders;

    my $obj = shift;

    return (
        qw(Allow Methods Service Server ISTag
            Opt-body-type Max-Connections Options-TTL Service-ID
            Preview Transfer-Preview Transfer-Ignore
            Transfer-Complete), $obj->SUPER::_validHeaders
            );
}

sub status ($;$) {

    # Purpose:  Gets/sets response status code
    # Returns:  Boolean/string
    # Usage:    $rv = $obj->status($code);
    # Usage:    $code = $obj->status;

    my $obj    = shift;
    my $status = shift;
    my $rv;

    pdebug( 'entering w/%s', ICAPDEBUG1, $status );
    pIn();

    if ( defined $status ) {

        # Write mode
        if ( $obj->exists( '_status_text', $status ) ) {
            $rv = $obj->set( '_status', $status );
        } else {
            $obj->error("invalid status code passed: $status");
            $rv = 0;
        }

    } else {

        # Read mode
        $rv = $obj->get('_status');
    }

    pOut();
    pdebug( 'leaving w/rv: %s', ICAPDEBUG1, $rv );

    return $rv;
}

sub statusText ($;$) {

    # Purpose:  Returns associated status description string
    # Returns:  String
    # Usage:    $text = $obj->statusText($code);
    # Usage:    $text = $obj->statusText;

    my $obj    = shift;
    my $status = shift;
    my $rv;

    pdebug( 'entering w/%s', ICAPDEBUG1, $status );
    pIn();

    $status = $obj->get('_status') unless defined $status;
    if ( defined $status ) {
        ($rv) = $obj->subset( '_status_text', $status )
            if $obj->exists( '_status_text', $status );
    }

    $obj->error("invalid or undefined status")
        unless defined $rv;

    pOut();
    pdebug( 'leaving w/rv: %s', ICAPDEBUG1, $rv );

    return $rv;
}

sub sanityCheck ($) {

    # Purpose:  Checks for required information
    # Returns:  Boolean
    # Usage:    $rv = $obj->sanityCheck;

    my $obj = shift;
    my $rv  = 1;
    my $t;

    $t = $obj->get('_status');
    unless ( defined $t and length $t ) {
        $obj->error('missing a valid request method');
        $rv = 0;
    }

    $t = $obj->get('_version');
    unless ( defined $t and length $t ) {
        $obj->error('missing a valid ICAP protocol version');
        $rv = 0;
    }

    $t = $obj->header('ISTag');
    unless ( defined $t and length $t ) {
        $obj->error('missing mandatory ISTag header');
        $rv = 0;
    }

    $obj->error('failed sanity check') unless $rv;
    $obj->error('failed sanity check') unless $rv;

    return $rv;
}

sub parse ($$) {

    # Purpose:  Parses message from passed input
    # Returns:  Boolean
    # Usage:    $rv = $obj->parse($input);

    my $obj   = shift;
    my $input = shift;
    my $rv    = 0;
    my ( $line, $s, $v );

    pdebug( 'entering w/%s, %s', ICAPDEBUG1, $obj, $input );
    pIn();

    if ( defined $input ) {

        # Purge internal state
        $obj->set( '_status', undef );

        # Parse
        $rv = $obj->SUPER::parse($input);

        if ($rv) {

            # Extract response specific fields
            $line = $obj->get('_start');
            ( $v, $s ) = ( $line =~ /^(\S+)\s+(\d+)/s );

            # Save the extracted information
            $rv = $obj->status($s) && $obj->version($v);

            # Final sanity check
            $rv = $obj->sanityCheck if $rv;
        }
    }

    pOut();
    pdebug( 'leaving w/rv: %s', ICAPDEBUG1, $rv );

    return $rv;
}

sub generate ($$) {

    # Purpose:  Generates an ICAP response
    # Returns:  String
    # Usage:    $response = $obj->generate($ref);

    my $obj = shift;
    my $out = shift;
    my $rv;

    if ( $obj->sanityCheck ) {

        # Build start line
        $obj->set( '_start', join ' ', ICAP_VERSION, $obj->status,
            $obj->statusText );

        # Generate ICAP message
        $rv = $obj->SUPER::generate($out);
    }

    return $rv;
}

1;

__END__

=head1 NAME

Net::ICAP::Response - ICAP Response Class

=head1 VERSION

$Id: lib/Net/ICAP/Response.pm, 0.04 2017/04/12 15:54:19 acorliss Exp $

=head1 SYNOPSIS

    use Net::ICAP::Response;
    use Net::ICAP::Common qw(:resp);

    $msg = new Net::ICAP::Response;
    $rv  = $msg->parse($fh);

    $method = $msg->status;
    $text   = $msg->statusText;

    $msg = Net::ICAP::Response->new(
        status  => ICAP_OK,
        headers => {
            ISTag => 'sasieEcjEO',
            },
        );
    $rv = $msg->status(ICAP_CONTINUE);

    $rv = $msg->generate($fh);

=head1 DESCRIPTION

This module provides an ICAP Response class for parsing and generating ICAP
responses.  Additional methods available to this class are provided (and
documented) in L<Net::ICAP::Message>.

=head1 SUBROUTINES/METHODS

=head2 parse

See L<Net::ICAP::Message> documentation.

=head2 generate

See L<Net::ICAP::Message> documentation.

=head2 status

    $rv     = $msg->status($status);
    $status = $msg->method;

This method gets or sets the response status.  Only valid statuses are 
accepted and must be one listed as a constant in L<Net::ICAP::Common>.  No
provision exists at this moment to accept additional status codes.

=head2 statusText

    $text  = $msg->statusText;
    $text  = $msg->statusText($code);

This method returns a text string describing the status code's purpose.  IF no
code is specified it returns the string associated with the internal status
code currently set.

=head2 sanityCheck

This method performs some basic sanity checks that the internal state has
parsed, or can generate, a valid ICAP message.  This includes checking for the
presence of mandatory headers, but no validation is done on the accompanying
values.

This method is used internally by both the B<parse> and B<generate> methods.

=head1 DEPENDENCIES

=over

=item L<Class::EHierarchy>

=item L<Paranoid>

=back

=head1 BUGS AND LIMITATIONS 

=head1 AUTHOR 

Arthur Corliss (corliss@digitalmages.com)

=head1 LICENSE AND COPYRIGHT

This software is licensed under the same terms as Perl, itself. 
Please see http://dev.perl.org/licenses/ for more information.

(c) 2012, Arthur Corliss (corliss@digitalmages.com)

