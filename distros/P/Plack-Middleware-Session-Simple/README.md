# NAME

Plack::Middleware::Session::Simple - Make Session Simple

# SYNOPSIS

    use Plack::Builder;
    use Cache::Memcached::Fast;

    my $app = sub {
        my $env = shift;
        my $counter = $env->{'psgix.session'}->{counter}++;
        [200,[], ["counter => $counter"]];
    };
    
    builder {
        enable 'Session::Simple',
            store => Cache::Memcached::Fast->new({servers=>[..]}),
            cookie_name => 'myapp_session';
        $app
    };

# DESCRIPTION

Plack::Middleware::Session::Simple is a yet another session management module.
This middleware has compatibility with Plack::Middleware::Session by
supporting psgix.session and psgi.session.options. 
You can reduce unnecessary accessing to store and Set-Cookie header.

This module uses Cookie to keep session state. does not support URI based session state.

# OPTIONS

- store

    object instance that has get, set, and remove methods.

- cookie\_name

    This is the name of the session key, it defaults to 'simple\_session'.

- keep\_empty

    If disabled, Plack::Middleware::Session::Simple does not output Set-Cookie header and store session until session are used. You can reduce Set-Cookie header and access to session store that is not required. (default: true/enabled)

        builder {
            enable 'Session::Simple',
                cache => Cache::Memcached::Fast->new({servers=>[..]}),
                session_key => 'myapp_session',
                keep_empty => 0;
            mount '/' => sub {
                my $env = shift;
                [200,[], ["ok"]];
            },
            mount '/login' => sub {
                my $env = shift;
                $env->{'psgix.session'}->{user} = 'session user'
                [200,[], ["login"]];
            },
        };
        
        my $res = $app->(req_to_psgi(GET "/")); #res does not have Set-Cookie    
        my $res = $app->(req_to_psgi(GET "/login")); #res has Set-Cookie

    If you have a plan to use session\_id as csrf token, you must not disable keep\_empty.

- path

    Path of the cookie, this defaults to "/";

- domain

    Domain of the cookie, if nothing is supplied then it will not be included in the cookie.

- expires

    Cookie's expires date time. several formats are supported. see [Cookie::Baker](https://metacpan.org/pod/Cookie::Baker) for details.
    if nothing is supplied then it will not be included in the cookie, which means the session expires per browser session.

- secure

    Secure flag for the cookie, if nothing is supplied then it will not be included in the cookie.

- httponly

    HttpOnly flag for the cookie, if nothing is supplied then it will not be included in the cookie.

- sid\_generator

    CodeRef that used to generate unique session ids, by default it uses SHA1

- sid\_validator

    Regexp that used to validate session id in Cookie

- serializer

    serialize,deserialize method. Optional. This is useful with Cache::FastMmap

        my $cfm = Cache::FastMmap->new(raw_values => 1);
        my $decoder = Sereal::Decoder->new();
        my $encoder = Sereal::Encoder->new();
        builder {
          enable 'Session::Simple',
              store => $fm,
              serializer => [ sub { $encoder->encode($_[0]) }, sub { $decoder->decode($_[0]) } ],
          $app;
        };

# LICENSE

Copyright (C) Masahiro Nagano.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Masahiro Nagano <kazeburo@gmail.com>
