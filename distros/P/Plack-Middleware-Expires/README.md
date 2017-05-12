# NAME

Plack::Middleware::Expires - mod\_expires for plack

# SYNOPSIS

    use Plack::Builder;

    builder {
        enable 'Expires',
          content_type => qr!^image/!i,
          expires => 'access plus 3 months';
        $app;
    }

# DESCRIPTION

Plack::Middleware::Expires is Apache's mod\_expires for Plack.
This middleware controls the setting of Expires HTTP header and the max-age directive of the Cache-Control HTTP header in server responses.

**Note**:

- Expires works only for successful response,
- If an Expires HTTP header exists already, it will not be overridden by this middleware.

# CONFIGURATIONS

- content\_type

        content_type => qr!^image!,
        content_type => 'text/css',
        content_type => [ 'text/css', 'application/javascript', qr!^image/! ]

    Content-Type header to apply Expires

    also `content_type` accept CodeRef

        content_type => sub { my $env = shift; return 1 if $env->{..} }

- Expires

    Same format as the Apache mod\_expires

        expires => 'M3600' # last_modified + 1 hour
        expires => 'A86400' # access + 1 day
        expires => 'modification plus 3 years 3 month 3 day'
        expires => 'access plus 3 days'

# AUTHOR

Masahiro Nagano <kazeburo {at} gmail.com>

# SEE ALSO

[http://httpd.apache.org/docs/2.2/en/mod/mod\_expires.html](http://httpd.apache.org/docs/2.2/en/mod/mod_expires.html)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
