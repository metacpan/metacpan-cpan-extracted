[![Build Status](https://travis-ci.org/moznion/Plack-Request-WithEncoding.svg?branch=master)](https://travis-ci.org/moznion/Plack-Request-WithEncoding) [![Coverage Status](https://img.shields.io/coveralls/moznion/Plack-Request-WithEncoding/master.svg?style=flat)](https://coveralls.io/r/moznion/Plack-Request-WithEncoding?branch=master)
# NAME

Plack::Request::WithEncoding - Subclass of [Plack::Request](https://metacpan.org/pod/Plack::Request) which supports encoded requests.

# SYNOPSIS

    use Plack::Request::WithEncoding;

    my $app_or_middleware = sub {
        my $env = shift; # PSGI env

        # Example of $env
        #
        # $env = {
        #     QUERY_STRING   => 'query=%82%d9%82%b0', # <= encoded by 'cp932'
        #     REQUEST_METHOD => 'GET',
        #     HTTP_HOST      => 'example.com',
        #     PATH_INFO      => '/foo/bar',
        # };

        my $req = Plack::Request::WithEncoding->new($env);

        $req->env->{'plack.request.withencoding.encoding'} = 'cp932'; # <= specify the encoding method.

        my $query = $req->param('query'); # <= get parameters of 'query' that is decoded by 'cp932'.

        my $res = $req->new_response(200); # new Plack::Response
        $res->finalize;
    };

# DESCRIPTION

Plack::Request::WithEncoding is a subclass of [Plack::Request](https://metacpan.org/pod/Plack::Request) that supports encoded requests. It overrides many Plack::Request attributes to return decoded values.
This feature allows a single application to seamlessly handle a wide variety of different language code sets. Applications that must be able to handle many different translations at once will find this extension able to quickly solve that problem.

The target attributes to be encoded are described at ["SPECIFICATION OF THE ENCODING METHOD"](#specification-of-the-encoding-method).

# ATTRIBUTES of `Plack::Request::WithEncoding`

- encoding

    Returns an encoding method to decode parameters.

- query\_parameters

    Returns a reference of [Hash::MultiValue](https://metacpan.org/pod/Hash::MultiValue) instance that contains **decoded** query parameters.

- body\_parameters

    Returns a reference of [Hash::MultiValue](https://metacpan.org/pod/Hash::MultiValue) instance that contains **decoded** request body.

- parameters

    Returns a reference of [Hash::MultiValue](https://metacpan.org/pod/Hash::MultiValue) instance that contains **decoded** parameters. The parameters are merged with `query_parameters` and `body_parameters`.

- param

    Returns **decoded** parameters with a CGI.pm-compatible param method. This is an alternative method for accessing parameters in
    `$req->parameters`.
    Unlike CGI.pm, it does **not** allow setting or modifying query parameters.

        $value  = $req->param('foo');
        @values = $req->param('foo');
        @params = $req->param;

- raw\_query\_parameters

    This attribute is the same as `query_parameters` of [Plack::Request](https://metacpan.org/pod/Plack::Request).

- raw\_body\_parameters

    This attribute is the same as `body_parameters` of [Plack::Request](https://metacpan.org/pod/Plack::Request).

- raw\_parameters

    This attribute is the same as `parameters` of [Plack::Request](https://metacpan.org/pod/Plack::Request).

- raw\_param

    This attribute is the same as `param` of [Plack::Request](https://metacpan.org/pod/Plack::Request).

# SPECIFICATION OF THE ENCODING METHOD

You can specify the character-encoding to decode, like so;

    $req->env->{'plack.request.withencoding.encoding'} = 'utf-7'; # <= set utf-7

When this character-encoding wasn't given through `$req->env->{'plack.request.withencoding.encoding'}`, this module uses "utf-8" as the default character-encoding to decode.
It would be better to specify this character-encoding explicitly because the readability and understandability of the code behavior would be improved.

Once this value was specified by falsy value (e.g. \`undef\`, 0 and ''), this module returns **raw value** (i.e. never decodes).

The example of a code is shown below.

    print exists $req->env->{'plack.request.withencoding.encoding'} ? 'EXISTS'
                                                                    : 'NOT EXISTS'; # <= NOT EXISTS
    $query = $req->param('query'); # <= get parameters of 'query' that is decoded by 'utf-8' (*** YOU SHOULD NOT USE LIKE THIS ***)

    $req->env->{'plack.request.withencoding.encoding'} = undef; # <= explicitly specify the `undef`
    $query = $req->param('query'); # <= get parameters of 'query' that is not decoded (raw value)

    $req->env->{'plack.request.withencoding.encoding'} = 'cp932'; # <= specify the 'cp932' as encoding method
    $query = $req->param('query'); # <= get parameters of 'query' that is decoded by 'cp932'

# SEE ALSO

[Plack::Request](https://metacpan.org/pod/Plack::Request)

# LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

moznion <moznion@gmail.com>
