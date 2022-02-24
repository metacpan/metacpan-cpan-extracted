# NAME

Plack::Middleware::Auth::JWT - Token-based Auth (aka Bearer Token) using JSON Web Tokens (JWT)

# VERSION

version 0.906

# SYNOPSIS

    # use Crypt::JWT to decode the JWT
    use Plack::Builder;
    builder {
        enable "Plack::Middleware::Auth::JWT",
            decode_args => { key => '12345' },
        ;
        $app;
    };

    # or provide your own decoder in a callback
    use Plack::Builder;
    builder {
        enable "Plack::Middleware::Auth::JWT",
            decode_callback => sub {
                my $token = shift;
                ....
            },
        ;
        $app;
    };


    # curl -H 'Authorization: Bearer eyJhbG...'
    # if the JWT is valid, two keys will be added to $env->{psgix}
    # $env->{'psgix.token'}  = 'original_token'
    # $env->{'psgix.claims'} = { sub => 'bart' } # claims as hashref

# DESCRIPTION

`Plack::Middleware::Auth::JWT` helps you to use [JSON Web
Tokens](https://en.wikipedia.org/wiki/JSON_Web_Token) (or JWT) for
authentificating HTTP requests. Tokens can be provided in the
`Authorization` HTTP Header, or as a query parameter (though passing
the JWT via the header is the prefered method).

## Configuration

TODO

### decode\_args

See ["decode\_jwt" in Crypt::JWT](https://metacpan.org/pod/Crypt%3A%3AJWT#decode_jwt)

Please note that `key` might has to be passed as a string-ref or an object, see [Crypt::JWT](https://metacpan.org/pod/Crypt%3A%3AJWT)

It is **very much recommended** that you only allow the algorithms you are actually using by setting `accepted_alg`! Per default, 'none' is **not** allowed.

Hardcoded:

        decode_payload = 1
        decode_header  = 0

Different defaults:

        verify_exp = 1
        leeway     = 5

You either have to use `decode_args`, or provide a [decode\_callback](https://metacpan.org/pod/decode_callback).

### decode\_callback

Callback to decode the token. Gets the token as a string and the psgi-env, has to return a hashref with claims.

You have to either provide a callback, or use [decode\_args](https://metacpan.org/pod/decode_args).

### psgix\_claims

Default: `claims`

Name of the entry in `psgix` were the claims are stored, so you can get the (for example) `sub` claim via

    $env->{'psgix.claims'}->{sub}

### psgix\_token

Default: `token`

Name of the entry in `psgix` were the raw token is stored.

### token\_required

Default: `false`

If set to a true value, all requests need to include a valid JWT. Default false, so you have to check in your application code if a token was submitted.

### ignore\_invalid\_token

Default: `false`

If set to a true value, passing an invalid JWT will not abort the
requerst with status 401. Instead the app will be called as if no
token was passed at all.

You can use this to implement another token check in a later
middleware, or even in your app. Of course you will then have to check
for `$env->{psgix.token}` in your controller actions.

### token\_header\_name

Default: `Bearer`

Name of the token in the HTTP `Authorization` header. If you set it to `0`, headers will be ignored.

### token\_query\_name

Default: `token`

Name of the HTTP query param that contains the token. If you set it to `0`, tokens in the query will be ignored.

## Example

TODO, in the meantime you can take a look at the tests.

# SEE ALSO

- [Crypt::JWT](https://metacpan.org/pod/Crypt::JWT) - encode / decode JWTs using various algorithms. Very complete!
- [Introduction to JSON Web Tokens](https://jwt.io/introduction) - good overview.
- [Plack::Middleware::Auth::AccessToken](https://metacpan.org/pod/Plack::Middleware::Auth::AccessToken) - a more generic solution handling any kind of token. Does not handle token payload (`claims`).

# THANKS

Thanks to

- [validad.com](https://www.validad.com/) for supporting Open Source.
- [jwright](https://github.com/jwrightecs) for fixing a
regression in the tests caused by an update in [Crypt::JWT](https://metacpan.org/pod/Crypt%3A%3AJWT) error
messages. The same issue was also reported by SREZIC.
- [Michael R. Davis](https://github.com/mrdvt92) for fixing a typo.

# AUTHOR

Thomas Klausner <domm@plix.at>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017 - 2022 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
