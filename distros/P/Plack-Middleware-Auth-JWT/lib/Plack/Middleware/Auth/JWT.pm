package Plack::Middleware::Auth::JWT;

# ABSTRACT: Token-based Auth (aka Bearer Token) using JSON Web Tokens (JWT)

our $VERSION = '0.901';

use 5.010;
use strict;
use warnings;
use parent qw(Plack::Middleware);
use Plack::Util;
use Plack::Util::Accessor
    qw(decode_args decode_callback psgix_claims psgix_token token_required ignore_invalid_token token_header_name token_query_name);
use Plack::Request;
use Crypt::JWT qw(decode_jwt);

sub prepare_app {
    my $self = shift;

    # some defaults
    $self->psgix_claims('claims') unless $self->psgix_claims;
    $self->psgix_token('token')   unless $self->psgix_token;

    $self->token_header_name('bearer')
        unless defined $self->token_header_name;
    $self->token_header_name(undef)  unless $self->token_header_name;
    $self->token_query_name('token') unless defined $self->token_query_name;
    $self->token_query_name(undef)   unless $self->token_query_name;
    $self->token_required(0)         unless defined $self->token_required;
    $self->ignore_invalid_token(0)   unless defined $self->ignore_invalid_token;

    # either decode_args or decode_callback is required
    if ( my $cb = $self->decode_callback ) {
        die "decode_callback must be a code reference"
            unless ref($cb) eq 'CODE';
    }
    elsif ( my $args = $self->decode_args ) {
        $args->{decode_payload} = 1;
        $args->{decode_header}  = 0;
        $args->{verify_exp}     = 1 unless exists $args->{verify_exp};
        $args->{leeway}         = 5 unless exists $args->{leeway};
    }
    else {
        die
            "Either decode_callback or decode_args has to be defined when loading this Middleware";
    }
}

sub call {
    my ( $self, $env ) = @_;

    my $token;

    if ( $self->token_header_name && $env->{HTTP_AUTHORIZATION} ) {
        my $name = $self->token_header_name;
        my $auth = $env->{HTTP_AUTHORIZATION};
        $token = $1 if $auth =~ /^\s*$name\s+(.+)/i;
    }
    elsif ( my $name = $self->token_query_name ) {
        my $req = Plack::Request->new($env);
        $token = $req->query_parameters->get($name);
    }

    unless ($token) {
        return $self->unauthorized if $self->token_required;

        # no token found, but non required, so just call the app
        return $self->app->($env);
    }

    my $claims = eval {
        if ( my $cb = $self->decode_callback ) {
            return $cb->( $token, $env );
        }
        else {
            return decode_jwt( token => $token, %{ $self->decode_args } );
        }
    };
    if ($@) {
        if ($self->ignore_invalid_token) {
            return $self->app->($env);
        }
        else {
            # TODO hm, if token cannot be decoded: 401 or 400?
            return $self->unauthorized( 'Cannot decode JWT: ' . $@ );
        }
    }
    else {
        $env->{ 'psgix.' . $self->psgix_token }  = $token;
        $env->{ 'psgix.' . $self->psgix_claims } = $claims;
        return $self->app->($env);
    }

    # should never be reached, but just to make sure...
    return $self->unauthorized;
}

sub unauthorized {
    my $self = shift;
    my $body = shift || 'Authorization required';

    return [
        401,
        [   'Content-Type'   => 'text/plain',
            'Content-Length' => length $body
        ],
        [$body]
    ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::Auth::JWT - Token-based Auth (aka Bearer Token) using JSON Web Tokens (JWT)

=head1 VERSION

version 0.901

=head1 SYNOPSIS

  # use Crypt::JWT to decode the JWT
  use Plack::Builder;
  builder {
      enable "Plack::Middleware::Auth::JWT",
          decode_args => { key => '12345' },
      ;
      $app;
  };

  # or provide your own decoder in a callback
  use Plack::Builder;
  builder {
      enable "Plack::Middleware::Auth::JWT",
          decode_callback => sub {
              my $token = shift;
              ....
          },
      ;
      $app;
  };


  # curl -H 'Authorization: Bearer eyJhbG...'
  # if the JWT is valid, two keys will be added to $env->{psgix}
  # $env->{'psgix.token'}  = 'original_token'
  # $env->{'psgix.claims'} = { sub => 'bart' } # claims as hashref

=head1 DESCRIPTION

C<Plack::Middleware::Auth::JWT> helps you to use L<JSON Web
Tokens|https://en.wikipedia.org/wiki/JSON_Web_Token> (or JWT) for
authentificating HTTP requests. Tokens can be provided in the
C<Authorization> HTTP Header, or as a query parameter (though passing
the JWT via the header is the prefered method).

=head2 Configuration

TODO

=head3 decode_args

See L<Crypt::JWT/decode_jwt>

Please note that C<key> might has to be passed as a string-ref or an object, see L<Crypt::JWT>

It is B<very much recommended> that you only allow the algorithms you are actually using by setting C<accepted_alg>! Per default, 'none' is B<not> allowed.

Hardcoded:

        decode_payload = 1
        decode_header  = 0

Different defaults:

        verify_exp = 1
        leeway     = 5

You either have to use C<decode_args>, or provide a L<decode_callback>.

=head3 decode_callback

Callback to decode the token. Gets the token as a string and the psgi-env, has to return a hashref with claims.

You have to either provide a callback, or use L<decode_args>.

=head3 psgix_claims

Default: C<claims>

Name of the entry in C<psgix> were the claims are stored, so you can get the (for example) C<sub> claim via

  $env->{'psgix.claims'}->{sub}

=head3 psgix_token

Default: C<token>

Name of the entry in C<psgix> were the raw token is stored.

=head3 token_required

Default: C<false>

If set to a true value, all requests need to include a valid JWT. Default false, so you have to check in your application code if a token was submitted.

=head3 ignore_invalid_token

Default: C<false>

If set to a true value, passing an invalid JWT will not abort the
requerst with status 401. Instead the app will be called as if no
token was passed at all.

You can use this to implement another token check in a later
middleware, or even in your app. Of course you will then have to check
for C<< $env->{psgix.token} >> in your controller actions.

=head3 token_header_name

Default: C<Bearer>

Name of the token in the HTTP C<Authorization> header. If you set it to C<0>, headers will be ignored.

=head3 token_query_name

Default: C<token>

Name of the HTTP query param that contains the token. If you set it to C<0>, tokens in the query will be ignored.

=head2 Example

TODO, in the meantime you can take a look at the tests.

=head1 SEE ALSO

=over

=item * L<Cryp::JWT|https://metacpan.org/pod/Crypt::JWT> - encode / decode JWTs using various algorithms. Very complete!

=item * L<Introduction to JSON Web Tokens|https://jwt.io/introduction> - good overview.

=item * L<Plack::Middleware::Auth::AccessToken|https://metacpan.org/pod/Plack::Middleware::Auth::AccessToken> - a more generic solution handling any kind of token. Does not handle token payload (C<claims>).

=back

=head1 THANKS

Thanks to

=over

=item *

L<validad.com|https://www.validad.com/> for supporting Open Source.

=back

=head1 AUTHOR

Thomas Klausner <domm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
