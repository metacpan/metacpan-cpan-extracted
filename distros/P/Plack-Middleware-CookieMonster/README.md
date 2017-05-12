# NAME

Plack::Middleware::CookieMonster - Eats all your (session) cookies in case Plack::Middleware::StrackTrace ate your HTTP headers.

# SYNOPSIS

    # Only expire selected cookies
    enable 'CookieMonster', cookies_names => [ 'session_cookie', 'foobar_cookie' ];
    enable 'StackTrace';

    # Only expire selected cookies on a certain path
    enable 'CookieMonster', cookies_names => [ 'session_cookie', 'foobar_cookie' ], path => '/foo';
    enable 'StackTrace';

    # Expire all cookies the browser sent
    enable 'CookieMonster';
    enable 'StackTrace';

# DESCRIPTION

When developing a plack application with Plack::Middleware::StackTrace enabled,
you may sometimes find yourself in a situation where your current session for
your webapp is borked. Your app would usually clear any session cookies in that
case, but since Plack::Middleware::StackTrace will simply throw away any HTTP
headers your app sends, you'll be stuck to that session.

`Plack::Middleware::CookieMonster` will detect that `Plack::Middleware::StackTrace`
rendered a stack trace and will add `Set-Cookie` headers to the response so that
the cookies you configured or all cookies that the browser sent will be expired.

This middleware was written because I was too lazy to search the "clear cookies"
control in my browser and because I think we should automate as much as possible.

# CONFIGURATION

- cookie\_names

    You can provide a `cookie_names` parameter, pointing to an array-ref containing
    the names of all the cookies you want to clear. Otherwise, all cookies the browser
    sent will be expired.

- path

    If your session cookie comes with a path parameter, configure this middleware to
    expire the cookie(s) on that path. Otherwise, confusion will rule.

# AUTHOR

Manni Heumann

# SEE ALSO

[Plack::Middleware::StackTrace](https://metacpan.org/pod/Plack::Middleware::StackTrace)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
