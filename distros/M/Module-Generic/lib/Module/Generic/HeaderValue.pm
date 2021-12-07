##----------------------------------------------------------------------------
## Module Generic - ~/lib/Generic/HeaderValue.pm
## Version v0.1.1
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/11/03
## Modified 2021/12/07
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Module::Generic::HeaderValue;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    our $VERSION = 'v0.1.1';
    use overload (
        '""'     => 'as_string',
        bool     => sub{ return( $_[0] ) },  
        fallback => 1,
    );
    our $QUOTE_REGEXP = qr/([\\"])/;
    #
    # RegExp to match type in rfc7231 section 3.1.1.1
    # <https://datatracker.ietf.org/doc/html/rfc7231#page-8>
    # rfc2616, section 2.2
    # <https://datatracker.ietf.org/doc/html/rfc2616#section-2.2>
    #
    # media-type = type "/" subtype
    # type       = token
    # subtype    = token
    # e.g.: text/html; charset="utf-8"
    #
    # rfc6265 <https://datatracker.ietf.org/doc/html/rfc6265#page-8>
    # token = cookie-octet
    #
    # token syntax
    # rfc2616 <https://datatracker.ietf.org/doc/html/rfc2616#section-2.2>
    our $TOKEN_REGEXP = qr/[^[:cntrl:]()<>\@,;:\\"\/\[\]\?\=\{\}[:blank:]\h]+/;
    # "<any OCTET except CTLs, but including LWS>"
    # <https://datatracker.ietf.org/doc/html/rfc2616#section-2.2>
    our $TEXT_REGEXP  = qr/(?>[[:blank:]\h]|[^[:cntrl:]\"])*+/;
    
    # \x21\x23-\x2B\x2D-\x3A\x3C-\x5B\x5D-\x7E
    # our $COOKIE_DATA_RE  = qr/[^[:cntrl][:blank:]\h\"\,\;\\]+/;
    # our $COOKIE_DATA_RE  = qr/[^[:cntrl:]\"\;\\]+/;
    # our $TYPE_REGEXP  = qr/(?:[!#$%&'*+.^_`|~0-9A-Za-z-]+\/[!#$%&'*+.^_`|~0-9A-Za-z-]+)|$TOKEN_REGEXP/;
    # our $TOKEN_REGEXP = qr/[!#$%&'*+.^_`|~0-9A-Za-z-]+/;
    # our $TEXT_REGEXP  = qr/[\u000b\u0020-\u007e\u0080-\u00ff]+|$COOKIE_DATA_RE/;
};

sub init
{
    my $self  = shift( @_ );
    my $value = shift( @_ );
    no overloading;
    return( $self->error( "No value provided." ) ) if( !defined( $value ) || !length( $value ) );
    $value = [split( /[[:blank:]\h]*\=[[:blank:]\h]*/, $value, 2 )] if( !$self->_is_array( $value ) && index( $value, '=' ) != -1 );
    $self->{original}  = '';
    $self->{value}     = $self->_is_array( $value ) ? $value : [ $value ];
    $self->{decode}    = 0;
    $self->{encode}    = 0;
    $self->{params}    = {};
    $self->{token_max} = 0;
    $self->{value_max} = 0;
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
#     $self->message( 3, "Value array is set to: ", sub{ $self->SUPER::dump( $self->{value} ) });
#     $self->message( 3, "Setting params to: ", sub{ $self->SUPER::dump( $params ) });
    use overloading;
#     $self->message( 3, "Decode value is '", $self->decode, "' and is true ? ", $self->decode ? 'yes' : 'no', " (", overload::StrVal( $self->decode ), ")." );
    if( scalar( @{$self->{value}} ) > 1 && $self->decode )
    {
#         $self->message( 3, "Decoding header value's value '", $self->{value}->[1], "'." );
        $self->{value}->[1] = URI::Escape::uri_unescape( $self->{value}->[1] );
    }
    return( $self );
}

sub new_from_multi
{
    my $self = shift( @_ );
    my $s    = shift( @_ );
    return( $self->error( 'Header value is required' ) ) if( !defined( $s ) || !length( $s ) );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{debug} //= 0;
    $opts->{decode} //= 0;
    my $me = bless( $opts => ( ref( $self ) || $self ) );
    $me->message( 4, "Processing value '$s'" );
    my $parts = [];
    my $i = 0;
    if( $self->_is_array( $s ) )
    {
        $parts = $s;
    }
    else
    {
        # split by comma, but avoid comma that would be part of an attribute value, such
        # as in cookie's expires value: foo=val; Expires=Mon, 01 Nov 2021 08:12:10 GMT, bar=baz; Max-Age=3600
        # would be 2 cookies:
        #   foo=val; Expires=Mon, 01 Nov 2021 08:12:10 GMT
        #   bar=baz; Max-Age=3600
        # Here, the regexp part (\\.) is on purpose so that the separator can be captured when 
        # it is undef, which signals to us this is a new part
        foreach( split( /(\\.)|\,[[:blank:]]*(?=(?:[^\s\;\=]+(?:\=|\;|\,|\z)))/, $s ) ) 
        {
            defined( $_ ) ? do{ $parts->[$i] .= $_ } : do{ $i++ };
        }
    }
    # $me->message( 3, "Parts found are: ", sub{ $me->SUPER::dump( $parts )} );
    my $res = $self->new_array;
    for( my $j = 0; $j < scalar( @$parts ); $j++ )
    {
        my $o = $me->new_from_header( $parts->[$j] );
        return( $self->pass_error( $me->error ) ) if( !defined( $o ) );
        $res->push( $o );
    }
    return( $res );
}

sub new_from_header
{
    my $self = shift( @_ );
    my $s    = shift( @_ );
    return( $self->error( 'Header value is required' ) ) if( !defined( $s ) || !length( $s ) );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{debug} //= $self->debug || 0;
    $opts->{decode} //= $self->decode || 0;
    $opts->{encode} //= $self->encode || 0;
    $opts->{token_max} //= $self->token_max;
    $opts->{value_max} //= $self->value_max;
    $opts->{separator} //= '';
    unless( $self->_is_object( $self ) )
    {
        $self = bless( $opts => $self );
    }
    my $sep  = CORE::length( $opts->{separator} ) ? $opts->{separator} : ';';
    my @parts = ();
    my $i = 0;
    foreach( split( /(\\.)|$sep/, $s ) )
    {
        defined( $_ ) ? do{ $parts[$i] .= $_ } : do{ $i++ };
    }
    # $self->message( 3, "Field parts are: ", sub{ $self->SUPER::dump( \@parts ) } );
    my $header_val = shift( @parts );
    my( $n, $v ) = split( /[[:blank:]\h]*\=[[:blank:]\h]*/, $header_val, 2 );
    $self->message( 4, "Header value '$n' and its own value is '$v' (", defined( $v ) ? 'defined' : 'undefined', ")." );
    if( $opts->{decode} )
    {
        $n = URI::Escape::uri_unescape( $n );
        $v = URI::Escape::uri_unescape( $v ) if( defined( $v ) );
        $self->message( 4, "After decoding, header value is '$n' and its value is '$v'." );
    }
    my $obj = $self->new( defined( $v ) ? [$n, $v] : $n );
    $obj->debug( $opts->{debug} );
    $obj->decode( $opts->{decode} );
    $obj->encode( $opts->{encode} );
    my $token_max_len = 0;
    my $value_max_len = 0;
    $token_max_len = $opts->{token_max} if( defined( $opts->{token_max} ) && CORE::length( $opts->{token_max} ) );
    $value_max_len = $opts->{value_max} if( defined( $opts->{value_max} ) && CORE::length( $opts->{value_max} ) );

    foreach my $frag ( @parts )
    {
        $frag =~ s/^[[:blank:]\h]+|[[:blank:]\h]+$//g;
        # Values are forbidden from having "="
        # <https://datatracker.ietf.org/doc/html/rfc6265#section-5.2>
        my( $attribute, $value ) = split( /[[:blank:]\h]*\=[[:blank:]\h]*/, $frag, 2 );
        if( !defined( $attribute ) )
        {
            warn( ref( $self ), "::new_from_header(): Found undefined attribute while splitting fragment '", ( $frag // '' ), "' in header value '", ( $s // '' ), "'.\n" );
            next;
        }
        
        $self->message( 4, "\tAttribute is '$attribute' and value '", ( $value // '' ), "'. Fragment processed was '$frag'" );
        $value =~ s/^\"|\"$//g if( defined( $value ) );
        # Check character string and length. Should not be more than 255 characters
        # https://datatracker.ietf.org/doc/html/rfc1341
        # http://www.iana.org/assignments/media-types/media-types.xhtml
        # Won't complain if this does not meet our requirement, but will discard it silently
        if( $attribute =~ /^$TOKEN_REGEXP$/ && ( $token_max_len <= 0 || CORE::length( $attribute ) <= $token_max_len ) )
        {
            if( defined( $value ) )
            {
                if( $value =~ /^$TEXT_REGEXP$/ && ( $value_max_len <= 0 || CORE::length( $value ) <= $value_max_len ) )
                {
                    $self->message( 4, "\tAdding property \"$attribute\" with value \"$value\"." );
                    $obj->param( lc( $attribute ) => $value );
                }
                else
                {
                    $self->message( 2, "Value for property \"$attribute\" contained some illegal characters or exceeded the maximum size of '$value_max_len'." );
                    warnings::warn( "Value for property \"$attribute\" contained some illegal characters or exceeded the maximum size of '$value_max_len'.\n" ) if( warnings::enabled() );
                }
            }
            else
            {
                $self->message( 4, "\tAdding property \"$attribute\" with value undef." );
                $obj->param( lc( $attribute ) => undef );
            }
        }
        else
        {
            $self->message( 2, "Token \"$attribute\" contains illegal characters or exceeds the maximum size of '$token_max_len'." );
            warnings::warn( "Token \"$attribute\" contains illegal characters or exceeds the maximum size of '$token_max_len'.\n" ) if( warnings::enabled() );
        }
    }
    return( $obj );
}

sub as_string
{
    my $self = shift( @_ );
    if( !$self->original->defined || !$self->original->length )
    {
        my $string = $self->value_as_string;
        my $token_max_len = $self->token_max;
        my $value_max_len = $self->value_max;

        # Append parameters
        if( $self->params->length )
        {
            my $params = $self->params->keys->sort;
            # $self->message( 3, "Properties found: '", $params->join( "', '" ), "'" );
            for( my $i = 0; $i < $params->length; $i++ )
            {
                if( $params->[$i] !~ /^$TOKEN_REGEXP$/ )
                {
                    $self->message( 3, "Invalid parameter name: \"" . $params->[$i] . "\"" );
                    return( $self->error( "Invalid parameter name: \"" . $params->[$i] . "\"" ) );
                }
                elsif( $token_max_len > 0 && CORE::length( $params->[$i] ) )
                {
                    $self->message( 3, "Parameter name \"", substr( $params->[$i], 0, $token_max_len ), "\" exceeds the maximum length of $token_max_len" );
                    return( $self->error( "Parameter name \"", substr( $params->[$i], 0, $token_max_len ), "\" exceeds the maximum length of $token_max_len" ) );
                }
                if( length( $string ) > 0 )
                {
                    $string .= '; ';
                }
                # $self->message( 3, "Value for property '", $params->[$i], "' is '", $self->params->get( $params->[$i] ), "'." );
                # No escaping of property values
                # $string .= $params->[$i] . '=' . ( $self->encode ? URI::Escape::uri_escape( $self->params->get( $params->[$i] ) ) : $self->qstring( $self->params->get( $params->[$i] ) ) );
                my $value = $self->params->get( $params->[$i] );
                if( defined( $value ) )
                {
                    if( $value_max_len > 0 && CORE::length( $value ) > $value_max_len )
                    {
                        $self->message( 3, "Parameter \"", $params->[$i], "\" value exceeds the maximum length of $value_max_len" );
                        return( $self->error( "Parameter \"", $params->[$i], "\" value exceeds the maximum length of $value_max_len" ) );
                    }
                    my $qstr = $self->qstring( $value );
                    if( !defined( $qstr ) )
                    {
                        $self->message( 1, $self->error );
                        warn( $self->error );
                        next;
                    }
                    $string .= $params->[$i] . '=' . $qstr;
                }
                else
                {
                    $string .= $params->[$i];
                }
                # $self->message( 5, "Resulting string is now '$string'" );
            }
        }
        $self->original( $string );
    }
    return( $self->original->scalar );
}

sub decode { return( shift->_set_get_boolean( 'decode', @_ ) ); }

sub encode { return( shift->_set_get_boolean( 'encode', @_ ) ); }

sub original { return( shift->_set_get_scalar_as_object( 'original', @_ ) ); }

sub param
{
    my $self = shift( @_ );
    my $k = shift( @_ );
    if( @_ )
    {
        return( $self->params->set( $k => @_ ) );
    }
    return( $self->params->get( $k ) );
}

sub params { return( shift->_set_get_hash_as_mix_object( 'params', @_ ) ); }

sub qstring
{
    my $self = shift( @_ );
    my $str  = shift( @_ );

    # no need to quote tokens
    if( $str =~ /^$TOKEN_REGEXP$/ || $str =~ /^\"(.*?)\"$/ )
    {
        return( $str );
    }

    if( length( $str ) > 0 && $str !~ /^$TEXT_REGEXP$/ )
    {
        $self->message( 3, "Invalid parameter value '$str'" );
        return( $self->error( 'Invalid parameter value' ) );
    }

    $str =~ s/$QUOTE_REGEXP/\\$1/g;
    return( '"' . $str . '"' );
}

sub reset
{
    my $self = shift( @_ );
    $self->{original} = '';
    return( $self );
}

sub token_max { return( shift->_set_get_number( 'token_max', @_ ) ); }

sub value { return( shift->_set_get_array_as_object( 'value', @_ ) ); }

sub value_max { return( shift->_set_get_number( 'value_max', @_ ) ); }

sub value_as_string
{
    my $self = shift( @_ );
    $self->message( 3, "Value is: '", $self->value->join( "', '" )->scalar, "'." );
    my $string = '';
    if( $self->value->length )
    {
        my( $n, $v ) = $self->value->list;
        $self->message( 3, "header value is '$n' and its value (possibly null) is '$v'" );
        if( defined( $v ) && $n !~ /^$TOKEN_REGEXP$/ )
        {
            $self->message( 3, "Invalid token \"$n\"" );
            return( $self->error( "Invalid token \"$n\"" ) );
        }
        elsif( !defined( $v ) && $n !~ /^$TEXT_REGEXP$/ )
        {
            $self->message( 3, "Invalid value \"$n\"" );
            return( $self->error( "Invalid value \"$n\"" ) );
        }
        if( defined( $v ) && $self->encode )
        {
            $v = URI::Escape::uri_escape( $v );
        }
        $string = defined( $v ) ? join( '=', $n, $v ) : $n;
    }
    return( $string );
}

1;

# XXX POD
__END__

=encoding utf-8

=head1 NAME

Module::Generic::HeaderValue - Generic Header Value Parser

=head1 SYNOPSIS

    use Module::Generic::HeaderValue;
    my $hv = Module::Generic::HeaderValue->new( 'foo' ) || die( Module::Generic::HeaderValue->error, "\n" );
    my $hv = Module::Generic::HeaderValue->new( 'foo', bar => 2 ) || die( Module::Generic::HeaderValue->error, "\n" );
    print( "SomeHeader: $hv\n" );
    # will produce:
    SomeHeader: foo; bar=2
    my $cookie = "Set-Cookie: token=984.1635825594; Path=/; Expires=Thu, 01 Jan 1970 09:00:00 GMT"
    my $all = Module::Generic::HeaderValue->new_from_multi( $cookie );

=head1 VERSION

    v0.1.1

=head1 DESCRIPTION

This is a class to parse and handle header values, such as in HTTP, L<PO file|Text::PO>, L<WebSocket extension|WebSocket::Extension>, or L<cookies|Cookies> in accordance with L<rfc2616|https://datatracker.ietf.org/doc/html/rfc2616#section-4.2>

The object has stringification capability. For this see L</as_string>

=head1 CONSTRUCTORS

=head2 new

Takes a header value, and optionally an hash or hash reference of parameters and this returns the object.

Each parameter have a corresponding method, so please check their method documentation for details.

Supported parameters are:

=over 4

=item debug integer

See L<Module::Generic/debug>

=item decode boolean

=item encode boolean

=item params hash reference

=item token_max integer

=item value_max integer

=back

=head2 new_from_header

Takes a header value such as C<foo; bar=2> and this will parse it and return a new L<Module::Generic::HeaderValue> object.

If L</decode>, it will decode the value found, if any. For example:

    my $hv = Module::Generic::HeaderValue->new_from_header( "site_prefs=lang%3Den-GB" );

would become token C<site_prefs> with value C<lang=en-GB>

It will set the value as an array reference that can be retrieved with L</value> and as a string with L</value_as_string>

If the value is made of a token and a token value, such as in the example above, the array will be 2-elements long:

    ["site_prefs", "lang=en-GB"]

otherwise, such as in the example of C<text/html: encoding=utf-8>, the value will be a 1-element long array reference:

    ["text/html"]

Use L</value_as_string>, so you do not have to worry about this.

Each attribute token found such as C<encoding> in the example above, will be converted to lowercase before added in the C<params> hash reference that can be accessed with L</params>

You can control what acceptable attribute length and attribute's value length is by setting L</token_max> and L</value_max> respectively. If it is set to 0, then it will be understood as no length limit.

=head2 new_from_multi

Takes a header value that contains potentially multiple values separated by a proper comma and this returns an array object (L<Module::Generic::Array>) of L<Module::Generic::HeaderValue> objects.

    my $all = Module::Generic::HeaderValue->new_from_multi(
        q{site_prefs=lang%3Den-GB}; Path=/; Expires=Monday, 01-Nov-2021 17:12:40 GMT; SameSite=Strict, csrf=9849724969dbcffd48c074b894c8fbda14610dc0ae62fac0f78b2aa091216e0b.1635825594; Path=/account; Secure
    );

Note that the comma in this string is found to be a separator only when it is followed by some token itself followed by C<=>, C<;>, C<,> or the end of string.

=head1 METHODS

=head2 as_string

Returns the object as a string suitable to be added in a n HTTP header.

If L</encode> is set and there is a token value, then this will be url escaped.

An attribute value set to C<undef> will result in the attribute alone:

    my $hv = Module::Generic::HeaderValue->new(
        "site_prefs=lang%3Den-GB",
        decode => 1,
        encode => 1,
        params => { secure => undef }
    );

would result in:

    site_prefs=lang%3Den-GB; secure

=head2 decode

Boolean. If set to true, L</new_from_header> will uri-unescape the token value, if any. For example a header value of C<site_prefs=lang%3Den-GB> is made of a token C<site_prefs> and a token value C<lang%3Den-GB>, which once decoded will become C<lang=en-GB>, but a header value of C<text/html> has no token value and thus no decoding applies.

=head2 encode

Boolean. If set to true, then L</as_string> will encode the token value, if any. See above in L</decode>.

=head2 original

Cache value of the object stringified. It could also be set during object instantiation to provide the original header value.

    my $hv = Module::Generic::HeaderValue->new( 'foo', original => 'foo; bar=2' ) || 
        die( Module::Generic::HeaderValue->error );

=head2 param

Set or get an attribute and its value.

    $hv->param( encoding => 'utf-8' );
    $hv->param( secure => undef );

=head2 params

Set or get an hash object (L<Module::Generic::Hash>) of parameters.

=head2 qstring

Provided with a string and this returns a quoted version, if necessary.

=head2 reset

Remove the cached version of the stringification, i.e. set the object property C<original> to an empty string.

=head2 token_max

Integer. Default to 0. Set or get the maximum length of a token. which applies to an attribute.

A value of 0 means no limit.

=head2 value

Set or get the main header value. For example, in the case of C<foo; bar=2>, the main value here is C<foo>.

=head2 value_max

Integer. Default to 0. Set or get the maximum length of a token value. which applies to an attribute value.

A value of 0 means no limit.

=head2 value_as_string

Returns a header value, without any possible attribute, as a string properly formatted and uri-escaped, if necessary.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Module::Generic::Cookies>, L<Text::PO>. L<WebSocket::Extension>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated files under the same terms as Perl itself.

=cut
