# NAME

Plack::Middleware::Session::Simple::JWSCookie - Session::Simple with JWS(JSON Web Sigmature) Cookie

# SYNOPSIS

    use Plack::Middleware::Session::Simple::JWSCookie;

    use Plack::Builder;
    use Cache::Memcached::Fast;

    my $app = sub {
        my $env = shift;
        my $counter = $env->{'psgix.session'}->{counter}++;
        [200,[], ["counter => $counter"]];
    };

    # no signature
    builder {
        enable 'Session::Simple::JWSCookie',
            store => Cache::Memcached::Fast->new({servers=>[..]}),
            cookie_name => 'myapp_session';
        $app
    };

    # using HMAC Signature
    builder {
        enable 'Session::Simple::JWSCookie',
            store => Cache::Memcached::Fast->new({servers=>[..]}),
            cookie_name => 'myapp_session'
            secret => $hmac_secret,
            alg = 'HS256';
        $app
    };

# DESCRIPTION

Plack::Middleware::Session::Simple::JWSCookie is session management module
which has compatibility with Plack::Middleware::Session::Simple.

Session cookie include session metadata with signature using JSON Web Signature.
The session cookie prevents manipulation of the session ID,
and can detect the invalid session cookie without accessing storage.

# LICENSE

Copyright (C) ritou.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

ritou <ritou.06@gmail.com>
