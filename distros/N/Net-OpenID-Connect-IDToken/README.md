# NAME

Net::OpenID::Connect::IDToken - id\_token generation / verification module

# SYNOPSIS

    use Net::OpenID::Connect::IDToken qw/encode_id_token decode_id_token/;

    my $claims = +{
        jti   => 1,
        sub   => "http://example.owner.com/user/1",
        aud   => "http://example.client.com",
        iat   => 1234567890,
        exp   => 1234567890,
    };
    my $key = ... # HMAC shared secret or RSA private key or ...


    my $id_token;

    # encode id_token
    $id_token = encode_id_token($claims, $key, "HS256");

    # encode id_token with at_hash and/or c_hash
    $id_token = encode_id_token($claims, $key, "HS256", +{
        token => "525180df1f951aada4e7109c9b0515eb",
        code  => "f9101d5dd626804e478da1110619ea35",
    });


    my $decoded_claims;

    # decode id_token without JWT verification
    $decoded_claims = decode_id_token($id_token);

    # decode id_token with JWT verification
    $decoded_claims = decode_id_token($id_token, $key);

    # decode id_token with JWT, at_hash and/or c_hash verification
    $decoded_claims = decode_id_token($id_token, $key, +{
        token => "525180df1f951aada4e7109c9b0515eb",
        code  => "f9101d5dd626804e478da1110619ea35",
    });

# ERRORS

Exception will be thrown with error codes below when error occurs.
You can handle these exceptions by...

    eval { decode_id_token(...) };
    if ( my $e = $@ ) {
        if ( $e->code eq ERROR_IDTOKEN_TOKEN_HASH_NOT_FOUND ) {
            # error handling code herer
        }
    }

Other errors like 'id\_token itself is not valid JWT' might come from
underlying JSON::WebToken.

## ERROR\_IDTOKEN\_INVALID\_ALGORITHM

Thrown when invalid algorithm specified.

## ERROR\_IDTOKEN\_TOKEN\_HASH\_NOT\_FOUND

Thrown when tried to verify at\_hash with token but at\_hash not found.

## ERROR\_IDTOKEN\_TOKEN\_HASH\_INVALID

Thrown when tried to verify at\_hash with token but at\_hash was invalid.

## ERROR\_IDTOKEN\_CODE\_HASH\_NOT\_FOUND

Thrown when tried to verify c\_hash with token but at\_hash not found.

## ERROR\_IDTOKEN\_CODE\_HASH\_INVALID

Thrown when tried to verify c\_hash with token but at\_hash was invalid.

# DESCRIPTION

Net::OpenID::Connect::IDToken is a module to generate/verify IDToken of OpenID Connect.
See: http://openid.net/connect/

**THIS IS A DEVELOPMENT RELEASE. API MAY CHANGE WITHOUT NOTICE**.

# SEE ALSO

http://search.cpan.org/~xaicron/JSON-WebToken-0.07/

# LICENSE

Copyright (C) zentooo

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

zentooo <zentooo@gmail.com<gt>
