[![Actions Status](https://github.com/kfly8/p5-Plack-Middleware-SecureHeaders/actions/workflows/test.yml/badge.svg)](https://github.com/kfly8/p5-Plack-Middleware-SecureHeaders/actions) [![Coverage Status](http://codecov.io/github/kfly8/p5-Plack-Middleware-SecureHeaders/coverage.svg?branch=main)](https://codecov.io/github/kfly8/p5-Plack-Middleware-SecureHeaders?branch=main) [![MetaCPAN Release](https://badge.fury.io/pl/Plack-Middleware-SecureHeaders.svg)](https://metacpan.org/release/Plack-Middleware-SecureHeaders)
# NAME

Plack::Middleware::SecureHeaders - manage security headers middleware

# SYNOPSIS

```perl
use Plack::Builder;

builder {
    enable 'SecureHeaders';
    $app;
};
```

# DESCRIPTION

This middleware manages HTTP headers to protect against XSS attacks, insecure connections, content type sniffing, etc.
Specifically, this module manages two things. One is Content-Type validation. Second is using [HTTP::SecureHeaders](https://metacpan.org/pod/HTTP%3A%3ASecureHeaders) to set secure HTTP headers.

**NOTE**: To protect against these attacks, sanitization of user input values and other protections are also required.

## OPTIONS

Secure HTTP headers can be changed as follows:

```perl
use Plack::Builder;

builder {
    enable 'SecureHeaders',
        secure_headers => HTTP::SecureHeaders->new(
            x_frame_options => 'DENY'
        );

    $app;
};
```

# SEE ALSO

[HTTP::SecureHeaders](https://metacpan.org/pod/HTTP%3A%3ASecureHeaders)

# LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

kfly8 <kfly@cpan.org>
