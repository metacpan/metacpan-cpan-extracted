package Plack::Middleware::CSRFBlock;
$Plack::Middleware::CSRFBlock::VERSION = '0.10';
use parent qw(Plack::Middleware);
use strict;
use warnings;

# ABSTRACT: Block CSRF Attacks with minimal changes to your app

use Digest::SHA1;
use Time::HiRes qw(time);
use HTML::Parser;
use Plack::Request;
use Plack::TempBuffer;
use Plack::Util;
use Plack::Util::Accessor qw(
    parameter_name header_name add_meta meta_tag token_length
    session_key blocked onetime _token_generator logger
);

sub prepare_app {
    my ($self) = @_;

    $self->parameter_name('SEC') unless defined $self->parameter_name;
    $self->token_length(16) unless defined $self->token_length;
    $self->session_key('csrfblock.token') unless defined $self->session_key;

    # Upper-case header name and replace - with _
    my $header_name = uc($self->header_name || 'X-CSRF-Token');
    $header_name =~ s/-/_/g;
    $self->header_name($header_name);

    $self->_token_generator(sub {
        my $token = Digest::SHA1::sha1_hex(rand() . $$ . {} . time);
        substr($token, 0 , $self->token_length);
    });
}

sub log {
    my ($self, $level, $msg) = @_;

    $self->logger->({ level => $level, message => "CSRFBlock: $msg" });
}

sub call {
    my($self, $env) = @_;

    # cache the logger
    $self->logger($env->{'psgix.logger'} || sub { }) unless defined $self->logger;

    # Generate a Plack Request for this request
    my $request = Plack::Request->new($env);

    # We need a session
    my $session = $request->session;
    unless ($session) {
        $self->log( error => 'No session found!' );
        die "CSRFBlock needs Session." unless $session;
    }

    my $token = $session->{$self->session_key};
    if($request->method =~ m{^post$}i) {
        # Log the request with env info
        $self->log(debug => 'Got POST Request');

        # If we don't have a token, can't do anything
        return $self->token_not_found($env) unless $token;

        my $found;

        # First, check if the header is set correctly.
        $found = ( $request->header( $self->header_name ) || '') eq $token;

        $self->log(debug => 'Found in Header? : ' . ($found ? 1 : 0));

        # If the token wasn't set, let's check the params
        unless ($found) {
            my $val = $request->parameters->{ $self->parameter_name } || '';
            $found = $val eq $token;
            $self->log(debug => 'Found in parameters : ' . ($found ? 1 : 0));
        }

        return $self->token_not_found($env) unless $found;

        # If we are using onetime token, remove it from the session
        delete $session->{$self->session_key} if $self->onetime;
    }

    return $self->response_cb($self->app->($env), sub {
        my $res = shift;
        my $ct = Plack::Util::header_get($res->[1], 'Content-Type') || '';
        if($ct !~ m{^text/html}i and $ct !~ m{^application/xhtml[+]xml}i){
            return $res;
        }

        my @out;
        my $http_host = $request->uri->host;
        my $token = $session->{$self->session_key} ||= $self->_token_generator->();
        my $parameter_name = $self->parameter_name;

        my $p = HTML::Parser->new(
            api_version => 3,
            start_h => [sub {
                my($tag, $attr, $text) = @_;
                push @out, $text;

                no warnings 'uninitialized';

                $tag = lc($tag);
                # If we found the head tag and we want to add a <meta> tag
                if( $tag eq 'head' && $self->meta_tag) {
                    # Put the csrftoken in a <meta> element in <head>
                    # So that you can get the token in javascript in your
                    # App to set in X-CSRF-Token header for all your AJAX
                    # Requests
                    push @out, q{<meta name="} . $self->meta_tag . qq{" content="$token"/>};
                }

                # If tag isn't 'form' and method isn't 'post' we dont care
                return unless $tag eq 'form' && $attr->{'method'} =~ /post/i;

                if(
                    !($attr->{'action'} =~ m{^https?://([^/:]+)[/:]}
                            and $1 ne $http_host)
                ) {
                    push @out, '<input type="hidden" ' .
                               "name=\"$parameter_name\" value=\"$token\" />";
                }

                # TODO: determine xhtml or html?
                return;
            }, "tagname, attr, text"],
            default_h => [\@out , '@{text}'],
        );
        my $done;

        return sub {
            return if $done;

            if(defined(my $chunk = shift)) {
                $p->parse($chunk);
            }
            else {
                $p->eof;
                $done++;
            }
            join '', splice @out;
        }
    });
}

sub token_not_found {
    my ($self, $env) = (shift, shift);

    $self->log(error => 'Token not found, returning 403!');

    if(my $app_for_blocked = $self->blocked) {
        return $app_for_blocked->($env, @_);
    }
    else {
        my $body = 'CSRF detected';
        return [
            403,
            [ 'Content-Type' => 'text/plain', 'Content-Length' => length($body) ],
            [ $body ]
        ];
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::CSRFBlock - Block CSRF Attacks with minimal changes to your app

=head1 VERSION

version 0.10

=head1 SYNOPSIS

  use Plack::Builder;

  my $app = sub { ... }

  builder {
    enable 'Session';
    enable 'CSRFBlock';
    $app;
  }

=head1 DESCRIPTION

This middleware blocks CSRF. You can use this middleware without any modifications
to your application, in most cases. Here is the strategy:

=over 4

=item output filter

When the application response content-type is "text/html" or
"application/xhtml+xml", this inserts a hidden input tag that contains a token
string into C<form>s in the response body. For example, when the application
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

This affects C<form> tags with C<method="post">, case insensitive.

It is possible to add an optional meta tag by setting C<meta_tag> to a defined
value. The 'name' attribute of the HTML tag will be set to the value of
C<meta_tag>. For the previous example, when C<meta_tag> is set to
'csrf_token', the output will be:

  <html>
    <head><meta name="csrf_token" content="0f15ba869f1c0d77"/>
        <title>input form</title>
    </head>
    <body>
      <form action="/api" method="post"><input type="hidden" name="SEC" value="0f15ba869f1c0d77" />
        <input type="text" name="email" /><input type="submit" />
      </form>
  </html>

=item input check

For every POST requests, this module checks the C<X-CSRF-Token> header first,
then C<POST> input parameters. If the correct token is not found in either,
then a 403 Forbidden is returned by default.

Supports C<application/x-www-form-urlencoded> and C<multipart/form-data> for
input parameters, but any C<POST> will be validated with the C<X-CSRF-Token>
header.  Thus, every C<POST> will have to have either the header, or the
appropriate form parameters in the body.

=item javascript

This module can be used easily with javascript by having your javascript
provide the C<X-CSRF-Token> with any ajax C<POST> requests it makes.  You can
get the C<token> in javascript by getting the value of the C<csrftoken> C<meta>
tag in the page <head>.  Here is sample code that will work for C<jQuery>:

    $(document).ajaxSend(function(e, xhr, options) {
        var token = $("meta[name='csrftoken']").attr("content");
        xhr.setRequestHeader("X-CSRF-Token", token);
    });

This will include the X-CSRF-Token header with any C<AJAX> requests made from
your javascript.

=back

=head1 OPTIONS

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

=over 4

=item parameter_name (default:"SEC")

Name of the input tag for the token.

=item meta_tag (default:undef)

Name of the C<meta> tag added to the C<head> tag of
output pages.  The content of this C<meta> tag will be
the token value.  The purpose of this tag is to give
javascript access to the token if needed for AJAX requests.
If this attribute is not explicitly set the meta tag will not
be included.

=item header_name (default:"X-CSRF-Token")

Name of the HTTP Header that the token can be sent in.
This is useful for sending the header for Javascript AJAX requests,
and this header is required for any post request that is not
of type C<application/x-www-form-urlencoded> or C<multipart/form-data>.

=item token_length (default:16);

Length of the token string. Max value is 40.

=item session_key (default:"csrfblock.token")

This middleware uses L<Plack::Middleware::Session> for token storage. this is
the session key for that.

=item blocked (default:403 response)

The application called when CSRF is detected.

Note: This application can read posted data, but DO NOT use them!

=item onetime (default:FALSE)

If this is true, this middleware uses B<onetime> token, that is, whenever
client sent collect token and this middleware detect that, token string is
regenerated.

This makes your applications more secure, but in many cases, is too strict.

=back

=head1 SEE ALSO

L<Plack::Middleware::Session>

=head1 AUTHORS

=over 4

=item *

Rintaro Ishizaki <rintaro@cpan.org>

=item *

William Wolf <throughnothing@gmail.com>

=item *

Matthew Phillips <mattp@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Authors of Plack-Middleware-CSRFBlock.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
