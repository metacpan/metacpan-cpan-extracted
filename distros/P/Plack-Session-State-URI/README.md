[![Build Status](https://travis-ci.org/s-aska/p5-Plack-Session-State-URI.png?branch=master)](https://travis-ci.org/s-aska/p5-Plack-Session-State-URI)
# NAME

Plack::Session::State::URI - uri-based session state

# SYNOPSIS

    use Plack::Builder;
    use Plack::Session::Store::File;
    use Plack::Session::State::URI;

    my $app = sub {
        return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello Foo' ] ];
    };

    builder {
        enable 'Plack::Middleware::Session',
            store => Plack::Session::Store::File->new(
                dir => File::Temp->tempdir( 'XXXXXXXX', TMPDIR => 1, CLEANUP => 1 )
            ),
            state => Plack::Session::State::URI->new(
                session_key => 'sid'
            );
        $app;
    };

# DESCRIPTION

Plack::Session::State::URI is uri-based session state

# AUTHOR

Shinichiro Aska <s.aska.org {at} gmail.com>

# SEE ALSO

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
