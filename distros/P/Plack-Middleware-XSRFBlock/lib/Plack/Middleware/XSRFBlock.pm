package Plack::Middleware::XSRFBlock;
{
  $Plack::Middleware::XSRFBlock::DIST = 'Plack-Middleware-XSRFBlock';
}
$Plack::Middleware::XSRFBlock::VERSION = '0.0.11';
use strict;
use warnings;
use parent 'Plack::Middleware';


use Digest::HMAC_SHA1 'hmac_sha1_hex';
use HTML::Escape qw(escape_html);
use HTML::Parser;
use HTTP::Status qw(:constants);

use Plack::Response;
use Plack::Util;
use Plack::Util::Accessor qw(
    blocked
    cookie_expiry_seconds
    cookie_name
    cookie_is_session_cookie
    cookie_options
    inject_form_input
    logger
    meta_tag
    token_per_request
    parameter_name
    header_name
    secret
    _token_generator
);

sub prepare_app {
    my $self = shift;

    # this needs a value if we aren't given one
    $self->parameter_name( $self->parameter_name || 'xsrf_token' );

    # default to 1 so we inject hidden inputs to forms
    $self->inject_form_input(1) unless defined $self->inject_form_input;

    # store the cookie_name
    $self->cookie_name( $self->cookie_name || 'PSGI-XSRF-Token' );

    # cookie is session cookie
    $self->cookie_is_session_cookie( $self->cookie_is_session_cookie || 0 );

    # extra optional options for the cookie
    $self->cookie_options( $self->cookie_options || {} );

    # default to one token per session, not one per request
    my $token_per_request = $self->token_per_request ? 1 : 0;
    $self->token_per_request(
      ref $self->token_per_request eq 'CODE'
      ? $self->token_per_request
      : sub { $token_per_request }
    );

    # default to a cookie life of three hours
    $self->cookie_expiry_seconds( $self->cookie_expiry_seconds || (3 * 60 * 60) );

    $self->_token_generator(sub{
        my $data    = rand() . $$ . {} . time;
        my $key     = "@INC";
        my $digest  = hmac_sha1_hex($data, $key);

        if (defined $self->secret) {
            my $sig = hmac_sha1_hex($digest, $self->secret);
            $digest .= "--$sig";
        }

        return $digest;
    });
}

sub call {
    my $self    = shift;
    my $env     = shift;

    # cache the logger
    $self->logger($env->{'psgix.logger'} || sub { })
        unless defined $self->logger;

    # we'll need the Plack::Request for this request
    my $request = Plack::Request->new($env);

    # grab the cookie where we store the token
    my $cookie_value = $request->cookies->{$self->cookie_name};

    # deal with form posts
    if ($request->method =~ m{^post$}i) {
        $self->log(info => 'POST submitted');

        # X- header takes precedence over form fields
        my $val;
        $val = $request->header( $self->header_name )
            if (defined $self->header_name);
        # fallback to the parameter value
        $val ||= $request->parameters->{ $self->parameter_name };

        # it's not easy to decide if we're missing the X- value or the form
        # value
        # We can say for certain that if we don't have the header_name set
        # it's a missing form parameter
        # If it is set ... well, either could be missing
        if (not defined $val and not length $val) {
            # no X- headers expected
            return $self->xsrf_detected(
                { env => $env, msg => 'form field missing' } )
              if not defined $self->header_name;

            # X- headers and form data allowed
            return $self->xsrf_detected(
                { env => $env, msg => 'xsrf token missing' } )

        }

        # get the value we expect from the cookie
        return $self->xsrf_detected( { env => $env, msg => 'cookie missing' } )
          unless defined $cookie_value;

        # reject if the form value and the token don't match
        return $self->xsrf_detected( { env => $env, msg => 'invalid token' } )
          if $val ne $cookie_value;

        return $self->xsrf_detected( { env => $env,
                msg => 'invalid signature' } )
          if $self->invalid_signature($val);
    }

    return Plack::Util::response_cb($self->app->($env), sub {
        my $res = shift;

        # Determine whether to create a new token, based on the request
        $cookie_value = $self->_token_generator->()
            if $self->token_per_request->( $self, $request, $env );

        # make it easier to work with the headers
        my $headers = Plack::Util::headers($res->[1]);

        # we can't form-munge anything non-HTML
        my $ct = $headers->get('Content-Type') || '';
        if($ct !~ m{^text/html}i and $ct !~ m{^application/xhtml[+]xml}i){
            return $res;
        }

        # GITHUB ISSUE #12 - set cookie after we're happy it's HTML
        # get the token value from:
        # - cookie value, if it's already set
        # - from the generator, if we don't have one yet
        my $token = $cookie_value ||= $self->_token_generator->();

        my %cookie_expires;
        unless ( $self->cookie_is_session_cookie ) {
            $cookie_expires{expires} = time + $self->cookie_expiry_seconds;
        }

        # we need to add our cookie
        $self->_set_cookie(
            $token,
            $res,
            path    => '/',
            %cookie_expires,
        );

        return $res unless $self->inject_form_input;

        # escape token (someone might have tampered with the cookie)
        $token = escape_html($token);

        # let's inject our field+token into the form
        my @out;
        my $http_host = $request->uri->host;
        my $parameter_name = $self->parameter_name;

        my $p = HTML::Parser->new( api_version => 3 );

        $p->handler(default => [\@out , '@{text}']),

        # we need *all* tags, otherwise we end up with gibberish as the final
        # page output
        # i.e. unless there's a better way, we *can not* do
        #    $p->report_tags(qw/head form/);

        # inject our xSRF information
        $p->handler(
            start => sub {
                my($tag, $attr, $text) = @_;
                # we never want to throw anything away
                push @out, $text;

                # for easier comparison
                $tag = lc($tag);

                # If we found the head tag and we want to add a <meta> tag
                if( $tag eq 'head' && $self->meta_tag) {
                    # Put the csrftoken in a <meta> element in <head>
                    # So that you can get the token in javascript in your
                    # App to set in X-CSRF-Token header for all your AJAX
                    # Requests
                    push @out,
                        sprintf(
                            q{<meta name="%s" content="%s"/>},
                            $self->meta_tag,
                            $token
                        );
                }

                # If tag isn't 'form' and method isn't 'post' we dont care
                return unless
                       defined $tag
                    && defined $attr->{'method'}
                    && $tag eq 'form'
                    && $attr->{'method'} =~ /post/i;

                if(
                    !(
                        defined $attr
                            and
                        exists $attr->{'action'}
                            and
                        $attr->{'action'} =~ m{^https?://([^/:]+)[/:]}
                            and
                        defined $http_host
                            and
                        $1 ne $http_host
                    )
                ) {
                    push @out,
                        sprintf(
                            '<input type="hidden" name="%s" value="%s" />',
                            $parameter_name,
                            $token
                        );
                }

                # TODO: determine xhtml or html?
                return;
            },
            "tagname, attr, text",
        );

        # we never want to throw anything away
        $p->handler(
            default => sub {
                my($tag, $attr, $text) = @_;
                push @out, $text;
            },
            "tagname, attr, text",
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

sub invalid_signature {
    my ($self, $value) = @_;

    # we dont use signed cookies
    return if !defined $self->secret;

    # cookie isn't signed
    my ($token, $signature) = split /--/, $value;
    return 1 if !defined $signature || $signature eq '';

    # signature doesn't validate
    return hmac_sha1_hex($token, $self->secret) ne $signature;
}

sub xsrf_detected {
    my $self    = shift;
    my $args    = shift;
    my $env = $args->{env};
    my $msg = $args->{msg}
        ? sprintf('XSRF detected [%s]', $args->{msg})
        : 'XSRF detected';

    $self->log(error => 'XSRF detected, returning HTTP_FORBIDDEN');

    if (my $app_for_blocked = $self->blocked) {
        return $app_for_blocked->($env, $@, app => $self->app);
    }

    return [
        HTTP_FORBIDDEN,
        [ 'Content-Type' => 'text/plain', 'Content-Length' => length($msg) ],
        [ $msg ]
    ];
}

sub log {
    my ($self, $level, $msg) = @_;
    $self->logger->({ level => $level, message => "XSRFBlock: $msg" });
}

# taken from Plack::Session::State::Cookie
# there's a very good reason why we have to do the cookie setting this way ...
# I just can't explain it clearly right now
sub _set_cookie {
    my($self, $id, $res, %options) = @_;

    # TODO: Do not use Plack::Response
    my $response = Plack::Response->new(@$res);
    $response->cookies->{ $self->cookie_name } = +{
        value => $id,
        %options,
        %{ $self->cookie_options },
    };

    my $final_r = $response->finalize;
    $res->[1] = $final_r->[1]; # headers
}

1;



# ABSTRACT: Block XSRF Attacks with minimal changes to your app

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::XSRFBlock - Block XSRF Attacks with minimal changes to your app

=head1 VERSION

version 0.0.11

=head1 SYNOPSIS

The simplest way to use the plugin is:

    use Plack::Builder;

    my $app = sub { ... };

    builder {
        enable 'XSRFBlock';
        $app;
    }

You may also over-ride any, or all of these values:

    builder {
        enable 'XSRFBlock',
            parameter_name          => 'xsrf_token',
            cookie_name             => 'PSGI-XSRF-Token',
            cookie_options          => {},
            cookie_expiry_seconds   => (3 * 60 * 60),
            token_per_request       => 0,
            meta_tag                => undef,
            inject_form_input       => 1,
            header_name             => undef,
            secret                  => undef,
            blocked                 => sub {
                                        return [ $status, $headers, $body ]
                                    },
        ;
        $app;
    }

=head1 DESCRIPTION

This middleware blocks XSRF. You can use this middleware without any
modifications to your application.

=head1 OPTIONS

=over 4

=item parameter_name (default: 'xsrf_token')

The name assigned to the hidden form input containing the token.

=item cookie_name (default: 'PSGI-XSRF-Token')

The name of the cookie used to store the token value.

=item cookie_expiry_seconds (default: 3*60*60)

The expiration time in seconds of the XSRF token

=item cookie_is_session_cookie (default: 0)

If set to a true value, the XSRF token cookie will be set as a session cookie
and C<cookie_expiry_seconds> will be ignored.

=item cookie_options (default: {})

Extra cookie options to be set with the cookie.  This is useful for things like
setting C<HttpOnly> to tell the browser to only send it with HTTP requests,
and C<Secure> on the cookie to force the cookie to only be sent on SSL requests.

    builder {
        enable 'XSRFBlock', cookie_options => { secure => 1, httponly => 1 };
    }

=item token_per_request (default: 0)

If this is true a new token is assigned for each request made (but see below).

This may make your application more secure, but more susceptible to
double-submit issues.

If this is a coderef, the coderef will be evaluated with the following arguments:

=over

=item * The middleware object itself,

=item * The request,

=item * The environment

=back

If the result of the evaluation is a true value, a new token will be assigned.
This allows fine-grained control, for example to avoid assigning new tokens when
incidental requests are made (e.g. on-page ajax requests).

=item meta_tag (default: undef)

If this is set, use the value as the name of the meta tag to add to the head
section of output pages.

This is useful when you are using javascript that requires access to the token
value for making AJAX requests.

=item inject_form_input (default: 1)

If this is unset, hidden inputs will not be injected into your forms, and no
HTML parsing will be done on the page responses.

This can be useful if you only do AJAX requests, and can utilize headers
and/or cookies instead, and not need the extra overhead of processing
the HTML document every time.

=item header_name (default: undef)

If this is set, use the value as the name of the response heaer that the token
can be sent in. This is useful for non-browser based submissions; e.g.
Javascript AJAX requests.

=item secret (default: undef)

Signs the cookie with supplied secret (if set).

=item blocked (default: undef)

If this is set it should be a PSGI application that is returned instead of the
default HTTP_FORBIDDEN(403) and text/plain response.

This could be useful if you'd like to perform some action that's more in
keeping with your application - e.g. return a styled error page.

=back

=head1 ERRORS

The module emits various errors based on the cause of the XSRF detected. The
messages will be of the form C<XSRF detected [reason]>

=over 4

=item form field missing

The request was submitted but there was no value submitted in the form field
specified by <C$self->parameter_name> [default: xsrf_token]

=item xsrf token missing

The application has been configured to accept an 'X-' header and no token
value was found in either the header or a suitable form field. [default: undef]

=item cookie missing

There is no cookie with the name specified by C<$self->cookie_name> [default:
PSGI-XSRF-Token]

=item invalid token

The cookie token and form value were both submitted correctly but the values
do not match.

=item invalid signature

The cookies signature is invalid, indicating it was tampered with on the way
to the browser.

=back

=head2 invalid_signature($self, $value)

=head2 xsrf_detected($self, $args)

=head2 log($self, $level, $msg)

=head1 EXPLANATION

This module is similar in nature and intention to
L<Plack::Middleware::CSRFBlock> but implements the xSRF prevention in a
different manner.

The solution implemented in this module is based on a CodingHorror article -
L<Preventing CSRF and XSRF Attacks|http://www.codinghorror.com/blog/2008/10/preventing-csrf-and-xsrf-attacks.html>.

The driving comment behind this implementation is from
L<the Felten and Zeller paper|https://www.eecs.berkeley.edu/~daw/teaching/cs261-f11/reading/csrf.pdf>:

    When a user visits a site, the site should generate a (cryptographically
    strong) pseudorandom value and set it as a cookie on the user's machine.
    The site should require every form submission to include this pseudorandom
    value as a form value and also as a cookie value. When a POST request is
    sent to the site, the request should only be considered valid if the form
    value and the cookie value are the same.  When an attacker submits a form
    on behalf of a user, he can only modify the values of the form. An
    attacker cannot read any data sent from the server or modify cookie
    values, per the same-origin policy.  This means that while an attacker can
    send any value he wants with the form, he will be unable to modify or read
    the value stored in the cookie. Since the cookie value and the form value
    must be the same, the attacker will be unable to successfully submit a
    form unless he is able to guess the pseudorandom value.

=head2 What's wrong with Plack::Middleware::CSRFBlock?

L<Plack::Middleware::CSRFBlock> is a great module.
It does a great job of preventing CSRF behaviour with minimal effort.

However when we tried to use it uses the session to store information - which
works well most of the time but can cause issues with session timeouts or
removal (for any number of valid reasons) combined with logging (back) in to
the application in another tab (so as not to interfere with the current
screen/tab state).

Trying to modify the existing module to provide the extra functionality and
behaviour we decided worked better for our use seemed too far reaching to try
to force into the existing module.

=head2 FURTHER READING

=over 4

=item * Preventing CSRF and XSRF Attacks

L<http://www.codinghorror.com/blog/2008/10/preventing-csrf-and-xsrf-attacks.html>

=item * Preventing Cross Site Request Forgery (CSRF)

L<https://www.golemtechnologies.com/articles/csrf>

=item * Cross-Site Request Forgeries: Exploitation and Prevention [PDF]

L<https://www.eecs.berkeley.edu/~daw/teaching/cs261-f11/reading/csrf.pdf>

=item * Cross-Site Request Forgery (CSRF) Prevention Cheat Sheet

L<https://www.owasp.org/index.php/Cross-Site_Request_Forgery_(CSRF)_Prevention_Cheat_Sheet>

=back

=head2 SEE ALSO

L<Plack::Middleware::CSRFBlock>,
L<Plack::Middleware>,
L<Plack>

=begin markdown

## BUILD STATUS

[![Build status](https://badge.buildkite.com/330e67514dd501f1827bcf33db423ccadf201caf5b2b563fbf.svg)](https://buildkite.com/chizography/plack-middleware-xsrfblock)

=end markdown

=head1 AUTHOR

Chisel <chisel@chizography.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Chisel Wright.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 CONTRIBUTORS

=for stopwords Chisel Wright Daniel Perrett Matthew Ryall Matthias Zeichmann Michael Kröll Sebastian Willert William Wolf

=over 4

=item *

Chisel <chisel.wright@net-a-porter.com>

=item *

Chisel Wright <chisel@chizography.net>

=item *

Daniel Perrett <dp13@sanger.ac.uk>

=item *

Matthew Ryall <matt.ryall@gmail.com>

=item *

Matthias Zeichmann <matthias.zeichmann@gmail.com>

=item *

Michael Kröll <michael.kroell@geizhals.at>

=item *

Sebastian Willert <willert@gmail.com>

=item *

William Wolf <throughnothing@gmail.com>

=back

=cut

__END__
# vim: ts=8 sts=4 et sw=4 sr sta
