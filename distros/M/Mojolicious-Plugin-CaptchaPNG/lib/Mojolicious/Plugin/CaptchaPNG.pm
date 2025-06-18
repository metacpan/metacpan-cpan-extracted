package Mojolicious::Plugin::CaptchaPNG;
# ABSTRACT: PNG captcha generation and validation Mojolicious plugin

use 5.024;
use strict;
use warnings;
use Crypt::URandom;
use Data::Password::Entropy 'password_entropy';
use GD::Image;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Exception;

our $VERSION = '1.08'; # VERSION

my $settings = {
    method      => 'any',
    path        => '/captcha',
    key         => '_plugin_captchapng',
    width       => 230,
    height      => 50,
    size        => 20,
    rotation    => 8,
    x           => 20,
    y_base      => 35,
    y_rotate    => 100,
    noise       => 1_250,
    background  => [ 255, 255, 255 ],
    text_color  => [ 'urand(128)', 'urand(128)', 'urand(128)' ],
    noise_color => [ 'urand(128) + 128', 'urand(128) + 128', 'urand(128) + 128' ],
    min_entropy => 40,
    value       => sub { int( urand( 10_000_000 - 1_000_000 ) ) + 1_000_000 },
    display     => sub {
        my ($display) = @_;
        $display =~ s/^(\d{2})(\d{3})/$1-$2-/;
        $display =~ s/(.)/ $1/g;
        return $display;
    },
    encrypt => undef,
    decrypt => undef,
};

use constant SIZE => 1 << 31;
use constant MASK => SIZE - 1;

sub urand(;$) {
    my $a = shift || 1;
    my ($b) = unpack( 'N', Crypt::URandom::urandom(4) ) & MASK;
    return $a * $b / SIZE;
}

sub register {
    my ( $self, $app, $overrides ) = @_;

    unless ( ref $settings->{encrypt} eq 'CODE' and ref $settings->{decrypt} eq 'CODE' ) {
        if (
            my $below_min_entropy = grep { password_entropy($_) < $settings->{min_entropy} } $app->secrets->@*
        ) {
            $app->log->warn(
                $below_min_entropy . ' Mojolicious application secret' .
                ( $below_min_entropy > 1 ? 's are' : ' is' ) .
                q{ below CaptchaPNG's minimum entropy}
            );
        }

        $app->log->warn(
            q{Application's Mojolicious::Sessions encryption is not active } .
            q{and there's not both encrypt and decrypt methods provided in CaptchaPNG's settings. } .
            q{Reverting to unsecured CaptchaPNG use, which is likely undesirable.}
        ) unless ( $app->sessions->can('encrypted') and $app->sessions->encrypted );
    }

    if ($overrides) {
        $settings->{$_} = $overrides->{$_} for ( keys %$overrides );
    }
    $settings->{routes} //= $app->routes;

    my $method = $settings->{method};
    $settings->{routes}->$method( $settings->{path} => sub {
        my ($c) = @_;

        my $image  = GD::Image->new( $settings->{width}, $settings->{height} );
        my $rotate = urand() / $settings->{rotation} * ( ( urand() > 0.5 ) ? 1 : -1 );
        my $value  = $settings->{value}->();

        $app->log->warn(
            'Mojolicious::Plugin::CaptchaPNG unable to read TTF font file, ' .
            'which will likely result in a blank captcha; "ttf" setting = ' .
            ( $settings->{ttf} // '>>undef<<' )
        ) unless ( defined $settings->{ttf} and -r $settings->{ttf} );

        $image->fill( 0, 0, $image->colorAllocate( map { eval $_ } $settings->{background}->@* ) );
        $image->stringFT(
            $image->colorAllocate( map { eval $_ } $settings->{text_color}->@* ),
            ( $settings->{ttf} // '' ),
            $settings->{size},
            $rotate,
            $settings->{x},
            $settings->{y_base} + $rotate * $settings->{y_rotate},
            $settings->{display}->($value),
        );

        for ( 1 .. 10 ) {
            my $index = $image->colorAllocate( map { eval $_ } $settings->{noise_color}->@* );
            $image->setPixel( urand( $settings->{width} ), urand( $settings->{width} ), $index )
                for ( 1 .. $settings->{noise} );
        }

        $value = $settings->{encrypt}->($value)
            if ( ref $settings->{encrypt} eq 'CODE' and ref $settings->{decrypt} eq 'CODE' );

        $c->session( $settings->{key} => $value );
        return $c->render( data => $image->png(9), format => 'png' );
    } );

    $app->helper(
        get_captcha_value => sub {
            my $value = $_[0]->session( $settings->{key} );
            $value = $settings->{decrypt}->($value)
                if ( ref $settings->{encrypt} eq 'CODE' and ref $settings->{decrypt} eq 'CODE' );
            return $value;
        }
    );

    $app->helper(
        set_captcha_value => sub {
            my ( $this, $value ) = @_;
            $value = $settings->{encrypt}->($value)
                if ( ref $settings->{encrypt} eq 'CODE' and ref $settings->{decrypt} eq 'CODE' );
            $this->session( $settings->{key} => $value );
            return;
        }
    );

    $app->helper(
        clear_captcha_value => sub {
            delete $_[0]->session->{ $settings->{key} };
            return;
        }
    );

    $app->helper(
        check_captcha_value => sub {
            my ( $c, $input_value ) = @_;
            my $session_value = $c->get_captcha_value;

            my $check = (
                defined $input_value and
                defined $session_value and
                $input_value eq $session_value
            ) ? 1 : 0;

            $c->clear_captcha_value if ($check);
            return $check;
        }
    );

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::CaptchaPNG - PNG captcha generation and validation Mojolicious plugin

=head1 VERSION

version 1.08

=for markdown [![test](https://github.com/gryphonshafer/Mojo-Plugin-CaptchaPNG/workflows/test/badge.svg)](https://github.com/gryphonshafer/Mojo-Plugin-CaptchaPNG/actions?query=workflow%3Atest)
[![codecov](https://codecov.io/gh/gryphonshafer/Mojo-Plugin-CaptchaPNG/graph/badge.svg)](https://codecov.io/gh/gryphonshafer/Mojo-Plugin-CaptchaPNG)

=for test_synopsis my($app);

=head1 SYNOPSIS

    # Simple Mojolicious
    $app->plugin( CaptchaPNG => { ttf => 'font.ttf' } );

    my $captcha_value = $app->get_captcha_value;
    my $success = $app->check_captcha_value($captcha_value);
    $app->clear_captcha_value;

    # Customized Mojolicious
    $app->plugin( CaptchaPNG => {
        routes      => $app->routes,
        method      => 'any',
        path        => '/captcha',
        key         => '_plugin_captchapng',
        width       => 230,
        height      => 50,
        ttf         => 'font.ttf',
        size        => 20,
        rotation    => 8,
        x           => 20,
        y_base      => 35,
        y_rotate    => 100,
        noise       => 1_250,
        background  => [ 255, 255, 255 ],
        text_color  => [ 'urand(128)', 'urand(128)', 'urand(128)' ],
        noise_color => [ 'urand(128) + 128', 'urand(128) + 128', 'urand(128) + 128' ],
        min_entropy => 40,
        value       => sub {
            return int(
                Mojolicious::Plugin::CaptchaPNG::urand(
                    10_000_000 - 1_000_000
                )
            ) + 1_000_000;
        },
        display => sub {
            my ($display) = @_;
            $display =~ s/^(\d{2})(\d{3})/$1-$2-/;
            $display =~ s/(.)/ $1/g;
            return $display;
        },
    } );

    # Mojolicious::Lite
    plugin( CaptchaPNG => { ttf => 'font.ttf' } );

=head1 DESCRIPTION

This module is a Mojolicious plugin for basic image captcha generation and
validation.

During registration (when C<plugin> is called), the plugin will setup a route
(which defaults to C</captcha>) that will respond with a generated PNG captcha.
The image is generated using L<GD::Image>. The plugin will also setup helper
methods to get, check, and clear the captcha value, which is stored in the
session.

Note that the assumption herein is that you're using Mojolicious verison 9.39 or
higher with L<Mojolicious::Sessions>'s C<encrypted> on. If so, the application's
Mojolicious secrets are checked for strong entropy and a warning is issued if
any have low entropy. (See C<min_entropy> below.) If not, then its expected
you'll provide your own captcha value encryption. (See C<encrypt> and C<decrypt>
below.)

=head1 SETTINGS

Much of the plugin's settings are customizable, but only 1 is required.

=head2 ttf

This is the only setting that's required. It is the path to a TTF font file that
will be used to generate the text in the captcha image.

=head2 routes

This a L<Mojolicious::Routes> object. If not set, it defaults to:

    $app->routes

=head2 method

The value to use when setting up the route method. If not set, it defaults to
C<any>.

=head2 path

The value to use when setting up the route path. If not set, it defaults to
C</captcha>.

=head2 key

When a captcha image is generated, the value of the captcha text is stored in
the session under this key. If not set, it defaults to C<_plugin_captchapng>.

=head2 width, height

The width and height of the generated captcha image. If not set, these default
to C<230> and C<50> respectively.

=head2 size

The font size of the text in the captcha image. If not set, it defaults to C<20>.

=head2 rotation

The amount of rotation to be made to the text in the captcha image. If not set,
it defaults to C<8>.

=head2 x

The C<x> coordinate L<GD::Image> uses for the text. If not set, it defaults to
C<20>.

=head2 y_base

The base value used for C<y> in L<GD::Image> for the text. If not set, it
defaults to C<35>.

=head2 y_rotate

The rotational value used for C<y> in L<GD::Image> for the text. If not set, it
defaults to C<100>.

=head2 noise

The amount of noise to generate in the image. If not set, it defaults to
C<1_250>.

=head2 background

An array reference of 3 expressions, which will be used to set the color of the
background in the image. Values will be evaluated before used. If not set, it
defaults to:

    [ 255, 255, 255 ]

=head2 text_color

An array reference of 3 expressions, which will be used to set the color of the
text in the image. Values will be evaluated before used. If not set, it defaults
to:

    [ 'urand(128)', 'urand(128)', 'urand(128)' ]

Note that C<urand> is provided by this library. See below.

=head2 noise_color

An array reference of 3 valexpressionses, which will be used to set the color of
the noise color in the image. Values will be evaluated before used. If not set,
it defaults to:

    [ 'urand(128) + 128', 'urand(128) + 128', 'urand(128) + 128' ]

Note that C<urand> is provided by this library. See below.

=head2 min_entropy

This is the minimum entropy level the application's Mojolicious secrets need to
achieve to avoid this plugin logging a warning. The default threshold is 40.

Note that C<min_entropy> is ignored if C<encrypt> and C<decrypt> are provided.

=head2 value

A subroutine reference that will be called to generate the value used for the
text of the captcha. If not set, it defaults to:

    sub {
        return int(
            Mojolicious::Plugin::CaptchaPNG::urand(
                10_000_000 - 1_000_000
            )
        ) + 1_000_000;
    }

=head2 display

A subroutine reference that will be called and passed a value. The subroutine
is expected to alter the value for display purposes. For example, adding spaces
or dashes or other such things. If not set, it defaults to:

    sub {
        my ($display) = @_;
        $display =~ s/^(\d{2})(\d{3})/$1-$2-/;
        $display =~ s/(.)/ $1/g;
        return $display;
    }

=head2 encrypt, decrypt

If these are set to subroutine references, they will be called to encrypt and
decrypt the value into and out of the session. They are passed the value to
encrypt or decrypt.

=head1 HELPER METHODS

=head2 get_captcha_value

This method (expected to be used in a L<Mojolicious> controller) will return the
stored captcha value from the most recent image generation.

    my $captcha_value = $app->get_captcha_value;

=head2 set_captcha_value

This method (likely never used, but if used would be expected to be used in a
L<Mojolicious> controller) will set a captcha value.

    $app->set_captcha_value(42);

=head2 check_captcha_value

This method (expected to be used in a L<Mojolicious> controller) expects a
captcha value and will return true or false if it matches the stored captcha
value.

    my $success = $app->check_captcha_value($captcha_value);

On success, the captcha value is removed from the session.

=head2 clear_captcha_value

Removes the captcha value from the session.

    $app->clear_captcha_value;

=head1 OTHER METHOD

=head2 urand

This method is a functional replacement of the core C<rand> but using
L<Crypt::URandom> for randomness.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Plugin>.

You can also look for additional information at:

=over 4

=item *

L<GitHub|https://github.com/gryphonshafer/Mojo-Plugin-CaptchaPNG>

=item *

L<MetaCPAN|https://metacpan.org/pod/Mojolicious::Plugin::CaptchaPNG>

=item *

L<GitHub Actions|https://github.com/gryphonshafer/Mojo-Plugin-CaptchaPNG/actions>

=item *

L<Codecov|https://codecov.io/gh/gryphonshafer/Mojo-Plugin-CaptchaPNG>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/Mojo-Plugin-CaptchaPNG>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/M/Mojo-Plugin-CaptchaPNG.html>

=back

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025-2050 by Gryphon Shafer.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
