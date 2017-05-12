package Mojolicious::Plugin::CaptchaRenderer;

use strict;
use warnings;
use File::Temp;
use File::Spec;

use base 'Mojolicious::Plugin';

BEGIN {
	die 'Module Image::Magick not properly installed' unless eval { require Image::Magick; 1 }
}

our $VERSION = 0.02;

sub register {
	my ($self,$app,$conf) = @_;
	
	$conf = {
		color          => 'black',
		bgcolor        => 'white',
		size           => 60,
		wave_amplitude => 7,
		wave_length    => 80,
		%$conf,
	};
	
	$app->renderer->add_helper(
		captcha => sub {
			my ($self,$code) = @_;
			
			my $img = Image::Magick->new(size => '400x400', magick => 'png');
			my $x; $x = $img->Read('gradient:#ffffff-#ffffff');
			
			$x = $img->Annotate(
				pointsize   => $conf->{'size'}, 
				fill        => $conf->{'color'}, 
				text        => $code, 
				geometry    => '+0+' . $conf->{'size'},
				$conf->{'font'} ? (font => $conf->{'font'}) : (),
			);
			
			warn $x if $x;
			$x = $img->Wave(amplitude => $conf->{'wave_amplitude'}, wavelength => $conf->{'wave_length'});
			warn $x if $x;
			$x = $img->Trim;
			warn $x if $x;
			
			my $body = '';
			
			{
				my $fh = File::Temp->new(UNLINK => 1, DIR => $ENV{MOJO_TMPDIR} || File::Spec->tmpdir);
				$x = $img->Write('png:' . $fh->filename);
				open $fh, '<', $fh->filename;
				local $/;
				$body = <$fh>;
			}
			return $body;
		}
	);
}

1;

=head1 NAME

Mojolicious::Plugin::CaptchaRenderer - captcha renderer for Mojolicious framework

=head1 VERSION

0.02

=head1 SYNOPSIS

   # Mojolicious::Lite
   plugin captcha_renderer => { size => 20, color => 'blue', wave_amplitude => 4};
   get '/img/code.png' => sub {
      my $self = shift;
      $self->render_data($self->captcha('cool captcha code'));
   }
   
   # Mojolicious
   $self->plugin(captcha_renderer => { size => 20, color => 'blue', wave_amplitude => 4});
   
   package MyApp::MyController;
   
   sub my_action {
      my $self = shift;
      $self->render_data($self->captcha('cool captcha code'));
   }
   
=head1 OPTIONS

=over 4

=item size - font size. By default 60

=item color - font color. By default black

=item font - font name. By default undef

=item bgcolor - captcha background color. By default white

=item wave_amplitude - amplitude of wave in captcha. By default 7

=item wave_length - length of wave in captcha. By dafault 80

=back

=head1 SUPPORT

=over 4

=item * Repository

L<http://github.com/konstantinov/Mojolicious-Plugin-CaptchaRenderer>

=back

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Plugin>, L<Mojolicious::Lite>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Dmitry Konstantinov. All right reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.