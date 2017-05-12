package Mojolicious::Plugin::Captcha;

use strict;
use warnings;

use Mojo::Base 'Mojolicious::Plugin';

use GD::SecurityImage;

our $VERSION = 0.02;

sub register {
	my ($self, $app, $conf) = @_;

	die ref($self), ": need session_name\n"
		unless $conf->{session_name};

	my $session_name = $conf->{session_name};

	my $captcha_string = sub {
		return shift->session->{ $session_name };
	};

	$app->helper(
		create_captcha => sub {
			my $self	= shift;
			my $image	= GD::SecurityImage->new( %{ $conf->{new} } );

			$image->random();
			$image->create( @{ $conf->{create} } );
			$image->particle( @{ $conf->{particle} } );

			my ( $image_data, $mime_type, $random_string ) = $image->out( %{ $conf->{out} } );

			$self->session->{ $session_name } = $random_string;

			return $image_data;
		}
	);

	$app->helper(
		validate_captcha => sub {
			my ( $self, $string, $case_sens ) = @_;
			return $case_sens
				? $string eq &{$captcha_string}
				: uc($string) eq uc(&{$captcha_string})
			;
		}
	);
}

1;

=head1 NAME

Mojolicious::Plugin::Captcha - create and validate captcha for Mojolicious framework

=head1 VERSION

0.02

=head1 SYNOPSIS

	# Mojolicious
	$self->plugin(
		'captcha',
		{
			session_name	=> 'captcha_string',
			out				=> {force => 'jpeg'},
			particle		=> [0,0],
			create			=> [qw/normal rect/],
			new				{
				rnd_data	=> [0...9, 'A'...'Z'],
				width		=> 80,
				height		=> 30,
				lines		=> 7,
				gd_font		=> 'giant',
			}
		}
	);

	package MyApp::MyController;

	sub captcha {
		my $self = shift;
		$self->render( data => $self->create_captcha );
	}

	sub some_post : Local {
		my ($self, $c) = @_;
		if ($self->validate_captcha($c->req->param('captcha')){
		..
		} else {
		..
		}
	}

=head1 DESCRIPTION

This plugin create and validate Captcha, using L<GD::SecurityImage>

=head1 METHODS

=head2 create_captcha

Create Captcha image and output it.

=head2 validate_captcha

Validate captcha string

	Accept optional second parameter to switch comparator case sensitivity (default is off, i.e. comparator make case insensivity comparing)

	# case sensitivity comparing
	$self->validate_captcha($self->param('captcha'), 1);

=head1 CONFIGURATION

=over 4

=item session_name

The keyword for storing captcha string

=item new

=item create

=item particle

=item out

These parameters are passed to each GD::Security's method. Please see L<GD::SecurityImage> for details.

=back

=head1 SUPPORT

=over 4

=item * Repository

L<https://bitbucket.org/zar/mojolicious-plugin-captcha>

=back

=head1 SEE ALSO

L<GD::SecurityImage>, L<Mojolicious>, L<Mojolicious::Plugin>

=head1 COPYRIGHT & LICENSE

Copyright 2014 zar. All right reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
