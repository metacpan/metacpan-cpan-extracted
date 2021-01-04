# NAME

Plack::Middleware::PrettyException - Capture exceptions and present them as HTML or JSON

# VERSION

version 1.009

# SYNOPSIS

    use Plack::Builder;
    builder {
        enable "Plack::Middleware::PrettyException",
        $app;
    };

    # then in your app in some controller / model / wherever

    # just die
    die "something went wrong";

    # use HTTP::Throwable
    http_throw(
        NotAcceptable => { message => 'You have to be kidding me!' }
    );

    # use a custom exception that implements http_status
    My::X::BadParam->throw({ status=>400, message=>'required param missing'})

    # clients get either
    #   JSON (if Accept-header indicates that JSON is expected)
    #   or a plain HTML error message

# DESCRIPTION

`Plack::Middleware::PrettyException` allows you to use exceptions in
your models (and also controllers, but they should be kept slim!) and
have them rendered as JSON or nice-ish HTML with very little fuzz.

But if your Plack app returns an HTTP status code indicating an error
(4xx/5xx) or just dies somewhere, the client also sees a pretty
exception.

So instead of capturing exceptions in your controller actions and
converting them to proper error messages, you just let the exception
propagate up to this middleware, which will then do the rendering.
This leads to much cleaner code in your controller, and to proper
exception usage in your model.

## Example

Here is am example controller implementing some kind of update:

    # SomeController.pm
    sub some_update_action {
        my ($self, $req, $id) = @_;

        my $item = $self->some_model->load_item($id);
        my $user = $req->get_user;
        $self->auth_model->may_edit($user, $item);

        my $payload = $req->get_json_payload;

        my $rv = $self->some_model->update_item($item, $payload);

        $req->json_response($rv);
    }

The lack of error handling makes the intention of this piece of code very clear. "The code is easy to reason about", as the current saying goes.

Here's the matching model

    # SomeModel
    sub load_item {
        my ($self, $id) = @_;

        my $item = $self->resultset('Foo')->find($id);
        return $item if $item;

        My::X::NotFound->throw({
            ident=>'cannot_find_foo',
            message=>'Cannot load Foo from id %{id}s',
            id=>$id,
        });
    }

`My::X::NotFound` could be a exception class based on [Throwable::X](https://metacpan.org/pod/Throwable::X):

    package My::X;
    use Moose;
    with qw(Throwable::X);
    
    use Throwable::X -all;
    
    has [qw(http_status)] => (
        is      => 'ro',
        default => 400,
        traits  => [Payload],
    );
    
    no Moose;
    __PACKAGE__->meta->make_immutable;
    
    package My::X::NotFound;
    use Moose;
    extends 'My::X';
    use Throwable::X -all;
    
    has id => (
        is     => 'ro',
        traits => [Payload],
    );
    
    has '+http_status' => ( default => 404, );

If we now call the endpoint with an invalid id, we get:

    ~$ curl -i http://localhost/thing/42/update
    HTTP/1.1 404 Not Found
    Content-Type: text/html;charset=utf-8
    
    <html>
      <head><title>Error 404</title></head>
      <body>
        <h1>Error 404</h1>
        <p>Cannot load Foo from id 42</p>
      </body>
    </html>

If we want JSON, we just need to tell the server:

    ~$ curl -i -H 'Accept: application/json' http://localhost/thing/42/update

    HTTP/1.1 404 Not Found
    Content-Type: application/json

    {"status":"error","message":"Cannot load Foo from id 42"}

Smooth!

## Content Negotiation / Force JSON

As of now there is no real content-negotiation, because all I need is
HTML and JSON. There is some semi-dumb checking of the
`Accept`-Header, but I only check for literal `application/json`
(while I should do the whole q-factor weighting dance).

If you want to force all your errors to JSON, pass `force_json => 1`
when loading the middleware:

    builder {
        enable "Plack::Middleware::PrettyException" => ( force_json => 1 );
        $app
    };

This will be replace in the near future by some proper content
negitiation and a new `default_response_encoding` field.

## Finetune HTML output via subclassing

The default HTML is rather basic^wugly. To finetune this, just
subclass `Plack::Middleware::PrettyException` and implement a method
called `render_html_error`. This method will be called with the HTTP
status code, the stringified error message, the original exception
object (if there was one!) and the original request `$env`. You can
then render it as fancy as you (or your graphic designer) wants.

Here's an example:

    package Oel::Middleware::Error;
    
    use 5.020;
    use strict;
    use warnings;
    use parent qw(Plack::Middleware::PrettyException);
    use Plack::Util::Accessor qw(html_page_model renderer);
    
    sub render_html_error {
        my ( $self, $status, $message, $exception, $env ) = @_;
    
        my %data = (base=>'/',title=>'Error '.$status, error => $message, code => $status );
        eval {
            if (my $page = $self->html_page_model->load('/_error/'.$status)) {
              $data{title} = $page->title;
              $data{description} = $page->teaser;
            }
        };
    
        my $rendered='';
        $self->renderer->tt->process('error.tt',\%data,\$rendered);
        return $rendered if $rendered;
    
        return "Error while rendering error: ".$self->renderer->tt->error;
    }
    
    1;

This middleware uses a `html_page_model` to retrieve the title and
description of the error page from a database (where admins can edit
those fields via a CMS). It uses
[Template::Toolkit](https://metacpan.org/pod/Template) to render the
page.

`html_page_model` and `renderer` are two attributes needed by this
middleware, implemented via `Plack::Util::Accessor`. You have to
provide some meaningful objects when loading the middleware, maybe
like this:

    use Plack::Builder;

    builder {
        enable "Plack::Middleware::PrettyException",
            renderer        => Oel::Renderer->new,
            html_page_model => Oel::Model::HtmlPage->new;

        $app;
    };

Of course you'll need to init `Oel::Renderer` and
`Oel::Model::HtmlPage`, so you'll probably want to use
[Bread::Board](https://metacpan.org/pod/Bread::Board) or
[OX](https://metacpan.org/pod/OX).

# SEE ALSO

- [Plack::Middleware::ErrorDocument](https://metacpan.org/pod/Plack::Middleware::ErrorDocument)

    Set Error Document based on HTTP status code. Does not capture errors.

- [Plack::Middleware::CustomErrorDocument](https://metacpan.org/pod/Plack::Middleware::CustomErrorDocument)

    Dynamically select error documents based on HTTP status code. Improved version of Plack::Middleware::ErrorDocument, also does not capture errors.

- [Plack::Middleware::DiePretty](https://metacpan.org/pod/Plack::Middleware::DiePretty)

    Show a 500 error page if you die. Converts **all** exceptions to 500 Server Error.

# THANKS

Thanks to

- [validad.com](https://www.validad.com/) for supporting Open Source.
- [oe1.orf.at](http://oe1.orf.at) for the motivation to extract the code from the Validad stack.
- [sixtease](https://metacpan.org/author/SIXTEASE) for coming up with `Oel` as the name for my example app (after miss-reading `oe1`).

# AUTHOR

Thomas Klausner <domm@plix.at>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 - 2021 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
