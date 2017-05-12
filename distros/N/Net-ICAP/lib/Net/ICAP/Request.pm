# Net::ICAP::Request -- Request object for ICAP
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

package Net::ICAP::Request;

use 5.008003;

use strict;
use warnings;
use vars qw($VERSION @ISA @_properties @_methods);
use Class::EHierarchy qw(:all);
use Net::ICAP::Common qw(:std :debug :req);
use Net::ICAP::Message;
use Paranoid::Debug;
use URI;

($VERSION) = ( q$Revision: 0.04 $ =~ /(\d+(?:\.(\d+))+)/s );

@ISA = qw(Net::ICAP::Message Class::EHierarchy);

@_properties = (
    [ CEH_RESTR | CEH_ARRAY, '_valid_methods', [qw(REQMOD RESPMOD OPTIONS)] ],
    [ CEH_RESTR | CEH_SCALAR, '_method' ],
    [ CEH_RESTR | CEH_SCALAR, '_url' ],
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
    $rv = $obj->method( $args{method} ) if exists $args{method};
    $rv = $obj->url( $args{url} ) if exists $args{url} and $rv;

    pOut();
    pdebug( 'leaving w/rv: %s', ICAPDEBUG1, $rv );

    return $rv;
}

sub _validHeaders ($) {

    # Purpose:  Returns a list of valid ICAP headers
    # Returns:  Array
    # Usage:    @val = $obj->_validHeaders;

    my $obj = shift;

    return ( qw(Host Authorization Allow From Referer User-Agent Preview),
        $obj->SUPER::_validHeaders );
}

sub method ($;$) {

    # Purpose:  Gets/sets method
    # Returns:  Boolean/String
    # Usage:    $rv     = $obj->method($method);
    # Usage:    $method = $obj->method;

    my $obj    = shift;
    my $method = shift;
    my $rv;

    pdebug( 'entering w/%s', ICAPDEBUG1, $method );
    pIn();

    if ( defined $method ) {

        # Write mode
        if ( grep { $_ eq $method } $obj->get('_valid_methods') ) {
            $rv = $obj->set( '_method', $method );
        } else {
            $obj->error("invalid method passed: $method");
            $rv = 0;
        }

    } else {
        $rv = $obj->get('_method');
    }

    pOut();
    pdebug( 'leaving w/rv: %s', ICAPDEBUG1, $rv );

    return $rv;
}

sub url ($;$) {

    # Purpose:  Gets/sets URL
    # Returns:  Boolean/String
    # Usage:    $rv     = $obj->url($url);
    # Usage:    $method = $obj->url;

    my $obj = shift;
    my $url = shift;
    my $rv;

    pdebug( 'entering w/%s', ICAPDEBUG1, $url );
    pIn();

    if ( defined $url ) {

        # Write mode
        $rv = $obj->set( '_url', $url );

    } else {

        # Read mode
        $rv = $obj->get('_url');
    }

    pOut();
    pdebug( 'leaving w/rv: %s', ICAPDEBUG1, $rv );

    return $rv;
}

sub authority ($) {

    # Purpose:  Returns the authority section of the URL
    # Returns:  String
    # Usage:    $auth = $obj->authority;

    my $obj = shift;
    my $url = $obj->set('_url');
    my ( $uri, $rv );

    pdebug( 'entering', ICAPDEBUG1 );
    pIn();

    if ( defined $url and length $url ) {
        $uri = URI->new($url);
        $rv  = $uri->authority;
    }

    pOut();
    pdebug( 'leaving w/rv: %s', ICAPDEBUG1, $rv );

    return $rv;
}

sub service ($) {

    # Purpose:  Returns the service section of the URL
    # Returns:  String
    # Usage:    $auth = $obj->service;

    my $obj = shift;
    my $url = $obj->get('_url');
    my ( $uri, $rv );

    pdebug( 'entering', ICAPDEBUG1 );
    pIn();

    if ( defined $url and length $url ) {
        $uri = URI->new($url);
        $rv  = $uri->path;
    }

    pOut();
    pdebug( 'leaving w/rv: %s', ICAPDEBUG1, $rv );

    return $rv;
}

sub query ($;$) {

    # Purpose:  Returns the query section of the URL
    # Returns:  String
    # Usage:    $auth = $obj->query;
    # Usage:    $auth = $obj->query($query_arg);

    my $obj   = shift;
    my $qname = shift;
    my $url   = $obj->get('_url');
    my ( $uri, %q, $rv );

    pdebug( 'entering', ICAPDEBUG1 );
    pIn();

    if ( defined $url and length $url ) {
        $uri = URI->new($url);
        $rv  = $uri->query;

        if ( defined $qname and length $qname ) {
            %q  = $uri->query_form;
            $rv = $q{$qname};
        }
    }

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

    $t = $obj->get('_method');
    unless ( defined $t and length $t ) {
        $obj->error('missing a valid request method');
        $rv = 0;
    }

    $t = $obj->get('_url');
    unless ( defined $t and length $t ) {
        $obj->error('missing a valid request URL');
        $rv = 0;
    }

    $t = $obj->get('_version');
    unless ( defined $t and length $t ) {
        $obj->error('missing a valid ICAP protocol version');
        $rv = 0;
    }

    $t = $obj->header('Host');
    unless ( defined $t and length $t ) {
        $obj->error('missing mandatory Host header');
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
    my ( $line, $m, $u, $v );

    pdebug( 'entering w/%s, %s', ICAPDEBUG1, $obj, $input );
    pIn();

    if ( defined $input ) {

        # Purge internal state
        $obj->set( '_method', undef );
        $obj->set( '_url',    undef );

        # Parse
        $rv = $obj->SUPER::parse($input);

        if ($rv) {

            # Extract request specific fields
            $line = $obj->get('_start');
            ( $m, $u, $v ) = ( $line =~ /^(\S+)\s+(\S+)\s+(\S+)$/s );

            # Save the extracted information
            $rv = $obj->method($m) && $obj->url($u) && $obj->version($v);

            # Perform basic sanity checks
            $rv = $obj->sanityCheck if $rv;
        }
    }

    $rv = 0 unless defined $rv;

    pOut();
    pdebug( 'leaving w/rv: %s', ICAPDEBUG1, $rv );

    return $rv;
}

sub generate ($$) {

    # Purpose:  Generates an ICAP request
    # Returns:  String
    # Usage:    $request = $obj->generate($ref);

    my $obj = shift;
    my $out = shift;
    my ( $url, $host, $rv );

    # Generate Host header from URL
    $url = $obj->url;
    if ( defined $url ) {
        ($host) = ( $url =~ m#^icap://([^:/]+)#si );
        $obj->header( 'Host', $host );
    }

    if ( $obj->sanityCheck ) {

        # Build start line
        $obj->set( '_start', join ' ', $obj->method, $obj->url,
            ICAP_VERSION );
        $rv = $obj->SUPER::generate($out);
    }

    return $rv;
}

1;

__END__

=head1 NAME

Net::ICAP::Request - ICAP Request Class

=head1 VERSION

$Id: lib/Net/ICAP/Request.pm, 0.04 2017/04/12 15:54:19 acorliss Exp $

=head1 SYNOPSIS

    use Net::ICAP::Request;
    use Net::ICAP::Common qw(:req);

    $msg = new Net::ICAP::Request;
    $rv  = $msg->parse($fh);

    $method = $msg->method;
    $url    = $msg->url;

    $auth       = $msg->authority;
    $service    = $msg->service;
    $query      = $msg->query;
    $query_arg  = $msg->query('lang');

    $msg = Net::ICAP::Request->new(
        method  => ICAP_REQMOD,
        url     => $url,
        headers => {
            Host    => 'localhost',
            },
        );
    $rv = $msg->method(ICAP_RESPMOD);
    $rv = $msg->url($url);

    $rv = $msg->generate($fh);

=head1 DESCRIPTION

This module provides an ICAP Request class for parsing and generating ICAP
requests.  Additional methods available to this class are provided (and
documented) in L<Net::ICAP::Message>.

=head1 SUBROUTINES/METHODS

=head2 parse

See L<Net::ICAP::Message> documentation.

=head2 generate

See L<Net::ICAP::Message> documentation.  This method will automatically
update the B<Host> header field based on the URL.

=head2 method

    $rv     = $msg->method($method);
    $method = $msg->method;

This method gets or sets the request method.  Only valid methods are accepted
and must be one of B<ICAP_REQMOD>, B<ICAP_RESPMOD>, or B<ICAP_OPTIONS>.  No
provision exists at this moment to accept custom methods.

=head2 url

    $rv     = $msg->url($url);
    $url    = $msg->url;

This method gets or sets the URL the request is going to.  No validation is
done on the passed value.

=head2 authority

    $auth = $msg->authority;

This returns the hostname/port section of the URL, assuming one was set and is
parseable by L<URI>.

=head2 service

    $service = $msg->service;

This returns the service (or path component of a URI) of the URL, assuming one
was set and is parseable by L<URI>.

=head2 query

    $query = $msg->query;
    $query_arg = $msg->query('lang');

This returns either the entire query string or the value of the specified
query argument as defined in the URL.  This uses B<query_form> of L<URI> which
assumes query components use B<application/x-www-form-urlencoded> format.

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

