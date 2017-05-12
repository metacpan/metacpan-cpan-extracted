# NAME

Plack::Middleware::CSRFBlock - Block CSRF Attacks with minimal changes to your app

# VERSION

version 0.10

# SYNOPSIS

    use Plack::Builder;

    my $app = sub { ... }

    builder {
      enable 'Session';
      enable 'CSRFBlock';
      $app;
    }

# DESCRIPTION

This middleware blocks CSRF. You can use this middleware without any modifications
to your application, in most cases. Here is the strategy:

- output filter

    When the application response content-type is "text/html" or
    "application/xhtml+xml", this inserts a hidden input tag that contains a token
    string into `form`s in the response body. For example, when the application
    response body is:

        <html>
          <head>
              <title>input form</title>
          </head>
          <body>
            <form action="/api" method="post">
              <input type="text" name="email" /><input type="submit" />
            </form>
        </html>

    This becomes:

        <html>
          <head>
              <title>input form</title>
          </head>
          <body>
            <form action="/api" method="post"><input type="hidden" name="SEC" value="0f15ba869f1c0d77" />
              <input type="text" name="email" /><input type="submit" />
            </form>
        </html>

    This affects `form` tags with `method="post"`, case insensitive.

    It is possible to add an optional meta tag by setting `meta_tag` to a defined
    value. The 'name' attribute of the HTML tag will be set to the value of
    `meta_tag`. For the previous example, when `meta_tag` is set to
    'csrf\_token', the output will be:

        <html>
          <head><meta name="csrf_token" content="0f15ba869f1c0d77"/>
              <title>input form</title>
          </head>
          <body>
            <form action="/api" method="post"><input type="hidden" name="SEC" value="0f15ba869f1c0d77" />
              <input type="text" name="email" /><input type="submit" />
            </form>
        </html>

- input check

    For every POST requests, this module checks the `X-CSRF-Token` header first,
    then `POST` input parameters. If the correct token is not found in either,
    then a 403 Forbidden is returned by default.

    Supports `application/x-www-form-urlencoded` and `multipart/form-data` for
    input parameters, but any `POST` will be validated with the `X-CSRF-Token`
    header.  Thus, every `POST` will have to have either the header, or the
    appropriate form parameters in the body.

- javascript

    This module can be used easily with javascript by having your javascript
    provide the `X-CSRF-Token` with any ajax `POST` requests it makes.  You can
    get the `token` in javascript by getting the value of the `csrftoken` `meta`
    tag in the page <head>.  Here is sample code that will work for `jQuery`:

        $(document).ajaxSend(function(e, xhr, options) {
            var token = $("meta[name='csrftoken']").attr("content");
            xhr.setRequestHeader("X-CSRF-Token", token);
        });

    This will include the X-CSRF-Token header with any `AJAX` requests made from
    your javascript.

# OPTIONS

    use Plack::Builder;

    my $app = sub { ... }

    builder {
      enable 'Session';
      enable 'CSRFBlock',
        parameter_name => 'csrf_secret',
        token_length => 20,
        session_key => 'csrf_token',
        blocked => sub {
          [302, [Location => 'http://www.google.com'], ['']];
        },
        onetime => 0,
        ;
      $app;
    }

- parameter\_name (default:"SEC")

    Name of the input tag for the token.

- meta\_tag (default:undef)

    Name of the `meta` tag added to the `head` tag of
    output pages.  The content of this `meta` tag will be
    the token value.  The purpose of this tag is to give
    javascript access to the token if needed for AJAX requests.
    If this attribute is not explicitly set the meta tag will not
    be included.

- header\_name (default:"X-CSRF-Token")

    Name of the HTTP Header that the token can be sent in.
    This is useful for sending the header for Javascript AJAX requests,
    and this header is required for any post request that is not
    of type `application/x-www-form-urlencoded` or `multipart/form-data`.

- token\_length (default:16);

    Length of the token string. Max value is 40.

- session\_key (default:"csrfblock.token")

    This middleware uses [Plack::Middleware::Session](http://search.cpan.org/perldoc?Plack::Middleware::Session) for token storage. this is
    the session key for that.

- blocked (default:403 response)

    The application called when CSRF is detected.

    Note: This application can read posted data, but DO NOT use them!

- onetime (default:FALSE)

    If this is true, this middleware uses __onetime__ token, that is, whenever
    client sent collect token and this middleware detect that, token string is
    regenerated.

    This makes your applications more secure, but in many cases, is too strict.

# SEE ALSO

[Plack::Middleware::Session](http://search.cpan.org/perldoc?Plack::Middleware::Session)

# AUTHORS

- Rintaro Ishizaki <rintaro@cpan.org>
- William Wolf <throughnothing@gmail.com>
- Matthew Phillips <mattp@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Authors of Plack-Middleware-CSRFBlock.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
