package Mojolicious::Plugin::Thumbnail;
use Mojo::Base 'Mojolicious::Plugin';

use Imager;

our $VERSION = '0.01';

has default_args => sub{+{
	src    => '',
	dst    => '',
	width  => 0,
	height => 0,
}};

sub register {
	my ($self, $app) = @_;

	$app->helper(thumbnail => sub {
		my $app  = shift;
		my $conf = @_ ? { @_ } : return;

		$conf = {%{$self->default_args}, %$conf};

		my $src_image = Imager->new();
		my $dst_image;

		die 'Source file missing' unless $src_image->open(file => $conf->{src});

		my ($src_width, $src_height) = ($src_image->getwidth, $src_image->getheight);
		my ($dst_width, $dst_height) = (int $conf->{width},   int $conf->{height}  );

		if (!$dst_height || ($dst_width && $src_width < $src_height)) {
			$dst_height = $src_height * $dst_width /$src_width;
		} else {
			$dst_width  = $src_width  * $dst_height/$src_height;
		}

		$dst_image = $src_image->scaleX(pixels => $dst_width)->scaleY(pixels => $dst_height);

		if ($conf->{width} && $conf->{height}) {
			$dst_image = $dst_image->crop(width => $conf->{width}, height => $conf->{height});
		}

		unless ($conf->{dst}) {
			$conf->{dst} = $conf->{src};
			$conf->{dst} =~ s{(.*?)\.(.+)$}{${1}_thumb.$2};
		}

		$dst_image->write(file => $conf->{dst}) or die $dst_image->errstr;
	});
}

1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Thumbnail - Mojolicious Plugin

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('Thumbnail');

  # Mojolicious::Lite
  plugin 'Thumbnail';

  # limit width, auto height
  $self->thumbnail(
    src   => 'public/img/img.jpg',
    dst   => 'public/img/img_thumb.jpg',
    width => 150,
  );

  # limit height, auto width
  $self->thumbnail(
    src   => 'public/img/img.jpg',
    dst   => 'public/img/img_thumb.jpg',
    width => 150,
  );

  # Resize and crop
  $self->thumbnail(
    src    => 'public/img/img.jpg',
    dst    => 'public/img/img_thumb.jpg',
    width  => 150,
    height => 150
  );

=head1 DESCRIPTION

L<Mojolicious::Plugin::Thumbnail> is a simple plugin for fast creating thumbnails using Imager.

=head1 METHODS

L<Mojolicious::Plugin::Thumbnail> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

Supported parameters:
 
=over 4

=item * 
C<src> – Source image path

=item * 
C<dst> – Destination image path (default: /path/to/sourcefilename_thumb.ext)

=item * 
C<width> – The new width of the image

=item * 
C<height> – The new height of the image

=back

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
