# -*- perl -*-
##----------------------------------------------------------------------------
## REST API Framework - ~/lib/Net/API/REST/Request.pm
## Version v1.0.0
## Copyright(c) 2023 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/09/01
## Modified 2023/06/10
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::REST::Request;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Apache2::API::Request );
    use vars qw( $ERROR $VERSION $SERVER_VERSION );
    use common::sense;
    use utf8 ();
    use version;
    use Net::API::REST::Cookies;
    use Net::API::REST::DateTime;
    use Net::API::REST::Query;
    use Net::API::REST::Status;
    use Nice::Try;
    our $VERSION = 'v1.0.0';
    our( $SERVER_VERSION, $ERROR );
};

use strict;
use warnings;

# init() is inherited

sub reply
{
    my $self = shift( @_ );
    my $code = shift( @_ );
    my $ref  = shift( @_ );
    my $r    = $self->request;
    my( $call_pack, $call_file, $call_line ) = caller;
    my $call_sub = ( caller(1) )[3];
    if( $code !~ /^[0-9]+$/ )
    {
        #$r->custom_response( Apache2::Const::SERVER_ERROR, "Was expecting an organisation id" );
        $r->status( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
        $r->rflush;
        # $r->send_http_header;
        $r->print( $self->json->encode({ 'error' => 'An unexpected server error occured', 'code' => 500 }) );
        $self->error( "http code to be used '$code' is invalid. It should be only integers." );
        return( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
    }
    if( ref( $ref ) ne 'HASH' )
    {
        $r->status( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
        $r->rflush;
        # $r->send_http_header;
        $r->print( $self->json->encode({ 'error' => 'An unexpected server error occured', 'code' => 500 }) );
        $self->error( "Data provided to send is not an hash ref." );
        return( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
    }
    my $msg = CORE::exists( $ref->{ 'success' } ) 
        ? $ref->{ 'success' } 
        : CORE::exists( $ref->{ 'error' } ) 
            ? $ref->{ 'error' } 
            : undef();
    $r->status( $code );
    if( defined( $msg ) )
    {
        $r->custom_response( $code, $msg );
    }
    else
    {
        $r->status( $code );
    }
    $r->rflush;
    $ref->{code} = $code if( !CORE::exists( $ref->{code} ) );
    try
    {
        $r->print( $self->json->encode( $ref ) );
        return( $code );
    }
    catch( $e )
    {
        $self->error( "An error occurred while calling Apache Request method \"print\": $e" );
        return( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
    }
}

# sub variables { return( shift->_set_get_object_without_init( 'variables', 'Net::API::REST::Endpoint::Variables', @_ ) ); }
sub variables { return( shift->_set_get_hash_as_mix_object( 'variables', @_ ) ); }

# Taken from http://www.perlmonks.org/bare/?node_id=319761
# This will do a split on a semi-colon, but being mindful if before it there is an escaped backslash
# For example, this would not be skipped: something\;here
# But this would be split: something\\;here resulting in something\ and here after unescaping
sub _split_str
{
    my $self = shift( @_ );
    my $s    = shift( @_ );
    return( {} ) if( !CORE::length( $s ) );
    my $sep  = @_ ? shift( @_ ) : ';';
    my @parts = ();
    my $i = 0;
    foreach( split( /(\\.)|$sep/, $s ) ) 
    {
        defined( $_ ) ? do{ $parts[$i] .= $_ } : do{ $i++ };
    }
    my $header_val = shift( @parts );
    my $param = {};
    foreach my $frag ( @parts )
    {
        $frag =~ s/^[[:blank:]]+|[[:blank:]]+$//g;
        my( $attribute, $value ) = split( /[[:blank:]]*\=[[:blank:]]*/, $frag, 2 );
        $value =~ s/^\"|\"$//g;
        ## Check character string and length. Should not be more than 255 characters
        ## http://tools.ietf.org/html/rfc1341
        ## http://www.iana.org/assignments/media-types/media-types.xhtml
        ## Won't complain if this does not meet our requirement, but will discard it silently
        if( $attribute =~ /^[a-zA-Z][a-zA-Z0-9\_\-]+$/ && CORE::length( $attribute ) <= 255 )
        {
            if( $value =~ /^[a-zA-Z][a-zA-Z0-9\_\-]+$/ && CORE::length( $value ) <= 255 )
            {
                $param->{ lc( $attribute ) } = $value;
            }
        }
    }
    return( { 'value' => $header_val, 'param' => $param } );
}

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Net::API::REST::Request - Apache2 Incoming Request Access and Manipulation

=head1 SYNOPSIS

    use Net::API::REST::Request;
    ## $r is the Apache2::RequestRec object
    my $req = Net::API::REST::Request->new( request => $r, debug => 1 );
    ## or, to test it outside of a modperl environment:
    my $req = Net::API::REST::Request->new( request => $r, debug => 1, checkonly => 1 );

=head1 VERSION

    v1.0.0

=head1 DESCRIPTION

The purpose of this module is to provide an easy access to various method to process and manipulate incoming request.

This module inherits all of its methods from L<Apache2::API::Request>. Please check its documentation directly.

For its alter ego to manipulate outgoing http response, use the L<Net::API::REST::Response> module.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>


L<Apache2::API::Request>, L<Apache2::API::Response>, L<Apache2::API>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2023 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
