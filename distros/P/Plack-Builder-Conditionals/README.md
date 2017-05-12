# NAME

Plack::Builder::Conditionals - Plack::Builder extension

# SYNOPSIS

    use Plack::Builder;
    use Plack::Builder::Conditionals;
    # exports "match_if, addr, path, method, header, browser, any, all"

    builder {
        enable match_if addr(['192.168.0.0/24','127.0.0.1']),
            "Plack::Middleware::ReverseProxy";

      enable match_if all( path(qr!^/private!), addr( '!', [qw!127.0.0.1 ::1!] ) ),
          "Plack::Middleware::Auth::Basic", authenticator => \&authen_cb;

      enable match_if sub { my $env = shift; $env->{HTTP_X_ENABLE_FRAMEWORK} },
          "Plack::Middleware::XFramework", framework => 'Test';

        $app;
    };

    use Plack::Builder::Conditionals -prefx => 'c';
    # exports "c_match_if, c_addr, c_path, c_method, c_header, c_any, c_all"



# DESCRIPTION

Plack::Builder::Conditionals is..

# FUNCTIONS

- match\_if

        enable match_if addr('127.0.0.1'), "Plack::Middleware::ReverseProxy";
        enable match_if sub { $_[0]->{REMOTE_ADDR} eq '127.0.0.1' }, "Plack::Middleware::ReverseProxy";

    As like Plack::Builder's enable\_if enable middleware if given conditions return true

- addr

        addr('127.0.0.1');
        addr([qw!192.168.0.0/24 127.0.0.1 ::1!]);
        addr('!','127.0.0.1');

    return true if REMOTE\_ADDR is found in the CIDR range. If first argument is '!', return the opposite result.
    This function supports IPv6 addresses

- path

        path('/')
        path(qr!^/(\w+)/!)
        path('!', qr!^/private!)

    matching PATH\_INFO

- method

        method('GET')
        method(qr/^(get|head)$/i)
        method(qw(GET HEAD))
        method('!','GET')
        method('!', qr/^(post|put)$/i)
        method('!', qw(POST PUT))
- header

        header('User-Agent',qr/iphone/)
        header('If-Modified-Since') #exists check
        header('!', 'User-Agent',qr/MSIE/)
- browser

        browser(qr/\bMSIE (7|8)/)
        browser('!',qr!^Mozilla/4!);

    Shortcut for header('User-Agent')

- all

        all( method('GET'), path(qr!^/static!) )

    return true if all conditions are return true

- any

        any( path(qr!^/static!), path('/favicon.ico') )

    return true if any condition return true

# EXPORT

    use Plack::Builder::Conditionals -prefx => 'c';
    # exports "c_match_if, c_addr, c_path, c_method, c_header, c_any, c_all"
    

you can add selected prefix to export functions

# AUTHOR

Masahiro Nagano <kazeburo {at} gmail.com>

# SEE ALSO

[Plack::Builder](http://search.cpan.org/perldoc?Plack::Builder)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
