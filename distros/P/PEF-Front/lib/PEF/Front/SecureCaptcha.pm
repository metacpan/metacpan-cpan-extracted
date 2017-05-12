package PEF::Front::SecureCaptcha;

use strict;
use warnings;
use GD::SecurityImage;

sub generate_image {
	my %args  = @_;
	my $pts   = int ($args{height} / 2.5 + 0.5);
	my $image = GD::SecurityImage->new(
		rndmax   => 1,
		ptsize   => $pts,
		angle    => "0E0",
		scramble => 1,
		lines    => int ($args{size} / 1.5 + 0.5),
		width    => $args{width} * $args{size},
		height   => $args{height},
		font     => $args{font}
	);
	$image->random($args{str});
	my $method = $args{font} =~ /\.ttf$/i ? 'ttf' : 'normal';
	$image->create($method => "ec")->particle($args{width} * $args{size}, 2);
	my ($image_data, $mime_type, $random_number) = $image->out(force => "jpeg");
	open (my $oi, ">", "$args{out_folder}$args{code}.jpg") or die $!;
	binmode $oi;
	syswrite $oi, $image_data;
	close $oi;
}

1;
