package Mojolicious::Plugin::Captcha::reCAPTCHA;

# ABSTRACT: use Captcha::reCAPTCHA in Mojolicious apps

use strict;
use warnings;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::ByteStream;
use Captcha::reCAPTCHA;

our $VERSION = 0.05;
$VERSION = eval $VERSION;

sub register {
    my $self = shift;
    my $app  = shift;
    my $conf = shift || {};

    $app->log->debug("Usage of Mojolicious::Plugin::Captcha::reCAPTCHA is deprecated; you should consider switching to Mojolicious::Plugin::ReCAPTCHAv2");

    die ref($self), ": need private and public key\n"
        unless $conf->{private_key} and $conf->{public_key};

    $app->attr(
        'recaptcha_obj' => sub {
            Captcha::reCAPTCHA->new;
        },
    );

    $app->attr( recaptcha_private_key => sub { $conf->{private_key} } );
    $app->attr( recaptcha_public_key  => sub { $conf->{public_key} } );
    $app->attr( recaptcha_use_ssl     => sub { $conf->{use_ssl} } );
    $app->attr( recaptcha_options     => sub { $conf->{options} } );

    $app->helper( recaptcha => sub { return shift->app->recaptcha_obj } );
    $app->helper(
        use_recaptcha => sub {
            my $self = shift;
            $self->stash( recaptcha_html => $self->recaptcha_html(@_) );
            return;
        }
    );
    $app->helper(
        recaptcha_html => sub {
            my ( $self, $err, $use_ssl, $options ) = @_;
            if ( !defined $use_ssl ) {
                if ( defined $self->app->recaptcha_use_ssl ) {
                    $use_ssl = $self->app->recaptcha_use_ssl;
                }
                elsif (    $self->req->url->base->scheme eq 'https'
                        or $self->req->headers->header('X-Forwarded-Protocol') eq 'https' )
                {
                    $use_ssl = 1;
                }
                else {
                    $use_ssl = undef;
                }
            }
            if ( !defined $options ) {
                $options = $self->app->recaptcha_options;
            }
            return Mojo::ByteStream->new(
				$self->recaptcha->get_html( $self->app->recaptcha_public_key, $err, $use_ssl, $options )
			);
        }
    );
    $app->helper(
        validate_recaptcha => sub {
            my ( $self, $params ) = @_;

            my $result = $self->recaptcha->check_answer( $self->app->recaptcha_private_key,
                                                         $self->tx->remote_address,
                                                         $params->{recaptcha_challenge_field},
                                                         $params->{recaptcha_response_field},
            );

            if ( !$result->{is_valid} ) {
                $self->stash( recaptcha_error => $result->{error} );
                return 0;
            }
            return 1;
        }
    );

    return;
} ## end sub register

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Captcha::reCAPTCHA - use Captcha::reCAPTCHA in Mojolicious apps

=head1 VERSION

version 0.05

=head1 SYNOPSIS

Provides a L<Captcha::reCAPTCHA> object in your Mojolicious app.

    use Mojolicious::Plugin::Captcha::reCAPTCHA;

    sub startup {
        my $self = shift;

        $self->plugin('Captcha::reCAPTCHA', { 
            private_key => 'the_public_key',
            public_key  => 'your_private_key',
            use_ssl     => 1,
            options     => { theme => 'white' },
        });
    }

C<private_key> and C<public_key> are mandatory, while C<use_ssl> and C<options> are optional.
Unless you have a specific reason to set a certain global value for C<use_ssl> you should 
probably just let the plugin decide when to use HTTPS requests.

In your mojolicious controller you can control everything by yourself by directly
invoking the C<get_html()> method of the L<Captcha::reCAPTCHA> object:

    $self->stash(
        recaptcha_html => $self->recaptcha->get_html( $public_key [, $error [, $use_ssl [, $options ] ] ] ),
    );

Following the same pattern you can also directly invoke C<check_answer()>:

    my $result = $self->recaptcha->check_answer(
        $private_key,
        $ip,
        $value_of_challenge_field,
        $value_of_response_field,
    );

Or you can use the new helpers.

=head1 NAME

Mojolicious::Plugin::Captcha::reCAPTCHA - use Captcha::reCAPTCHA in Mojolicious apps

=head1 VERSION

version 0.05

=head1 DEPRECATION NOTE

Mojolicious::Plugin::Captcha::reCAPTCHA is deprecated and you should consider 
switching to L<Mojolicious::Plugin::ReCAPTCHAv2>.

The latter one uses the newer v2 API of Googles reCAPTCHA service and also has
no dependencies besides Mojolicious (and IO::Socket::SSL, which again is a
dependency of Mojolicious itself).

=head1 METHODS/HELPERS

=head2 recaptcha

A helper named 'recaptcha' is created that can be used to access the L<Captcha::reCAPTCHA> 
object. 

  my $recaptcha_obj = $self->recaptcha;

=head2 use_recaptcha

This helper sets the key C<recaptcha_html> in the stash and uses the HTML as the value.

  $self->use_recaptcha;

It automatically uses the public key and the other configuration options you passed in
when registering the plugin.

You may explicitly pass in values for C<error>, C<use_ssl>, and C<options>.  If you do,
these params will take precedence over the configuration values. 
Pass C<undef> for positional params you either don't want to set or where you don't want
to override the config values:

  $self->use_recaptcha( undef, undef, { theme => 'red' } );

Unless explicitly passed in or set in the configuration, the correct value for C<use_ssl>
is automatically determined based on the current request (by looking at 
C<$self-\>req-\>url-\>base-\>scheme>). 

=head2 recaptcha_html

This helper works like C<use_recaptcha> but returns the HTML instead of setting a stash
value. Also accepts the same params as C<use_recaptcha()>.

Intended to be used in templates.

=head2 validate_recaptcha

Handles the validation of the recaptcha. If an error occurs, the stash variable
"recaptcha_error" is set.

  $self->validate_recaptcha( $params );

C<$params> is a hashref with parameters of the HTTP request.
Returns "true" (1) if validation was successful and "false" (0) otherwise.

=head1 AUTHORS

=over 4

=item *

Renee Baecker <module@renee-baecker.de>

=item *

Heiko Jansen <jansen@hbz-nrw.de>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Hochschulbibliothekszentrum NRW (hbz).

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=head1 AUTHORS

=over 4

=item *

Renee Baecker <module@renee-baecker.de>

=item *

Heiko Jansen <jansen@hbz-nrw.de>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Hochschulbibliothekszentrum NRW (hbz).

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
