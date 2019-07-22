package Plack::Middleware::PrettyException;

# ABSTRACT: Capture exceptions and present them as HTML or JSON

our $VERSION = '1.008';

use 5.010;
use strict;
use warnings;
use parent qw(Plack::Middleware);
use Plack::Util;
use Plack::Util::Accessor qw(force_json);
use HTTP::Headers;
use JSON::MaybeXS qw(encode_json);
use HTTP::Status qw(is_error);
use Scalar::Util 'blessed';
use Log::Any qw($log);

sub call {
    my $self = shift;
    my $env  = shift;

    my $r;
    my $error;
    my $exception;
    my $died = 0;
    eval {
        $r = $self->app->($env);
        1;
    } or do {
        my $e = $@;
        $died = 1;
        if ( blessed($e) ) {
            $exception = $e;
            if ( $e->can('message') ) {
                $error = $e->message;
            }
            else {
                $error = '' . $e;
            }
            $r->[0] =
                  $e->can('status_code') ? $e->status_code
                : $e->can('http_status') ? $e->http_status
                :                          500;
            $r->[0] ||= 500;

            if ( $r->[0] =~ /^3/ && $e->can('location') ) {
                push( @{ $r->[1] }, Location => $e->location );
                push( @{ $r->[2] }, $e->location ) unless $r->[2];
            }

        }
        else {
            $r->[0] = 500;
            $error = $e;
        }
    };

    return Plack::Util::response_cb(
        $r,
        sub {
            my $r = shift;

            if ( !$died && !is_error( $r->[0] ) ) {

                # all is ok!
                return;
            }
            if ( $r->[0] =~ /^3/ ) {

                # it's a redirect
                return;
            }

            # there was an error!

            unless ($error) {
                my $body = $r->[2] || 'error not found in body';
                $error = ref($body) eq 'ARRAY' ? join( '', @$body ) : $body;
            }

            my $location = join( '',
                map { $env->{$_} } qw(HTTP_HOST SCRIPT_NAME PATH_INFO) );
            $log->error( $location . ': ' . $error );

            my $orig_headers = HTTP::Headers->new( @{ $r->[1] } );
            my $err_headers = Plack::Util::headers( [] );
            my $err_body;

            # it already is JSON, so return that
            if ( $orig_headers->content_type =~ m{application/json}i ) {
                return;
            }

            # force json, or client requested JSON, so render errors as JSON
            if ($self->force_json
                || ( exists $env->{HTTP_ACCEPT}
                    && $env->{HTTP_ACCEPT} =~ m{application/json}i )
                ) {
                $err_headers->set( 'content-type' => 'application/json' );
                my $err_payload = { status => 'error', message => "" . $error };
                if ($exception && $exception->can('does')) {
                    if ($exception->does('Throwable::X')) {
                        my $payload = $exception->payload;
                        while (my ($k, $v) = each %$payload) {
                            $err_payload->{$k} = $v;
                        }
                        $err_payload->{ident} = $exception->ident;
                    }
                }

                $err_body = encode_json( $err_payload );
            }

            # return HTML as default
            else {
                $err_headers->set(
                    'content-type' => 'text/html;charset=utf-8' );
                $err_body = $self->render_html_error( $r->[0], $error, $exception, $env );
            }
            $r->[1] = $err_headers->headers;
            $r->[2] = [$err_body];
            return;
        }
    );
}

sub render_html_error {
    my ( $self, $status, $error, $exception, $env ) = @_;

    $status ||= 'unknown HTTP status code';
    $error  ||= 'unknown error';

    my $more='';
    if ($exception && $exception->can('does')) {
        my @more;
        if ($exception->does('Throwable::X')) {
            push(@more, "<li><strong>".$exception->ident."</strong></li>");
            push(@more, "<li><strong>".$exception->message."</strong></li>");
            my $payload = $exception->payload;
            while (my ($k, $v) = each %$payload) {
                push(@more,sprintf("<li>%s: %s</li>", $k, $v // ''));
            }
        }
        if (@more) {
            $more='<ul>'.join("\n",@more).'</ul>';
        }
    }

    return <<"UGLYERROR";
<html>
  <head><title>Error $status</title></head>
  <body>
    <h1>Error $status</h1>
    <p>$error</p>
    $more
  </body>
</html>
UGLYERROR
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::PrettyException - Capture exceptions and present them as HTML or JSON

=head1 VERSION

version 1.008

=head1 SYNOPSIS

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

=head1 DESCRIPTION

C<Plack::Middleware::PrettyException> allows you to use exceptions in
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

=head2 Example

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

C<My::X::NotFound> could be a exception class based on L<Throwable::X|https://metacpan.org/pod/Throwable::X>:

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

=head2 Content Negotiation / Force JSON

As of now there is no real content-negotiation, because all I need is
HTML and JSON. There is some semi-dumb checking of the
C<Accept>-Header, but I only check for literal C<application/json>
(while I should do the whole q-factor weighting dance).

If you want to force all your errors to JSON, pass C<force_json =E<gt> 1>
when loading the middleware:

  builder {
      enable "Plack::Middleware::PrettyException" => ( force_json => 1 );
      $app
  };

This will be replace in the near future by some proper content
negitiation and a new C<default_response_encoding> field.

=head2 Finetune HTML output via subclassing

The default HTML is rather basic^wugly. To finetune this, just
subclass C<Plack::Middleware::PrettyException> and implement a method
called C<render_html_error>. This method will be called with the HTTP
status code, the stringified error message, the original exception
object (if there was one!) and the original request C<$env>. You can
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

This middleware uses a C<html_page_model> to retrieve the title and
description of the error page from a database (where admins can edit
those fields via a CMS). It uses
L<Template::Toolkit|https://metacpan.org/pod/Template> to render the
page.

C<html_page_model> and C<renderer> are two attributes needed by this
middleware, implemented via C<Plack::Util::Accessor>. You have to
provide some meaningful objects when loading the middleware, maybe
like this:

  use Plack::Builder;

  builder {
      enable "Plack::Middleware::PrettyException",
          renderer        => Oel::Renderer->new,
          html_page_model => Oel::Model::HtmlPage->new;

      $app;
  };

Of course you'll need to init C<Oel::Renderer> and
C<Oel::Model::HtmlPage>, so you'll probably want to use
L<Bread::Board|https://metacpan.org/pod/Bread::Board> or
L<OX|https://metacpan.org/pod/OX>.

=head1 SEE ALSO

=over

=item * L<Plack::Middleware::ErrorDocument|https://metacpan.org/pod/Plack::Middleware::ErrorDocument>

Set Error Document based on HTTP status code. Does not capture errors.

=item * L<Plack::Middleware::CustomErrorDocument|https://metacpan.org/pod/Plack::Middleware::CustomErrorDocument>

Dynamically select error documents based on HTTP status code. Improved version of Plack::Middleware::ErrorDocument, also does not capture errors.

=item * L<Plack::Middleware::DiePretty|https://metacpan.org/pod/Plack::Middleware::DiePretty>

Show a 500 error page if you die. Converts B<all> exceptions to 500 Server Error.

=back

=head1 THANKS

Thanks to

=over

=item *

L<validad.com|https://www.validad.com/> for supporting Open Source.

=item *

L<oe1.orf.at|http://oe1.orf.at> for the motivation to extract the code from the Validad stack.

=item *

L<sixtease|https://metacpan.org/author/SIXTEASE> for coming up with C<Oel> as the name for my example app (after miss-reading C<oe1>).

=back

=head1 AUTHOR

Thomas Klausner <domm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
