package RPi::UnicornHatHD;
#
use Moo;
use strictures 2;
use namespace::clean;
#
our $VERSION = "0.07";
#
use WiringPi::API;
#
my $spi_channel      = 0;
my $spi_max_speed_hz = 9000000;
my $sof              = 0x72;

# _DELAY = 1.0/120 # Leave this to the user
#
sub BUILD {
    my ($self, $args) = @_;
    if ((WiringPi::API::spi_setup($spi_channel, $spi_max_speed_hz) < 0)) {
        die "failed to open the SPI bus...\n";
    }
}
has brightness => (is => 'rw', default => sub {.5});
has rotation   => (is => 'rw', default => sub {0});
has matrix => (is => 'lazy', clearer => 'clear');

sub _build_matrix {
    [map {
         [map { [0, 0, 0] } 1 .. 16]
     } 1 .. 16
    ];
}

sub show {
    my @buffer     = $_[0]->_rotate;
    my $brightness = $_[0]->brightness;
    WiringPi::API::spiDataRW(0,
                             [$sof, map { $_ * $brightness } @buffer],
                             1 + scalar @buffer);
}

sub off {
    my $s = shift;
    $s->clear();
    $s->show();
}

sub set_all {
    my $s = shift;
    my ($r, $g, $b)
        = $#_ == 2 ?
        @_
        : (map { hex $_ } $_[0] =~ m[#(\w{2})(\w{2})(\w{2})]);
    for my $x (0 .. 15) {
        for my $y (0 .. 15) {
            $s->matrix->[$x][$y] = [$r, $g, $b];
        }
    }
}

sub set_pixel {
    my $s = shift;
    my ($x, $y, $r, $g, $b)
        = $#_ == 4 ?
        @_
        : (@_[0 .. 1], map { hex $_ } $_[2] =~ m[#(\w{2})(\w{2})(\w{2})]);
    $s->matrix->[$x][$y] = [$r, $g, $b];
}

sub get_pixel {
    my $s = shift;
    my ($x, $y) = @_;
    $s->matrix->[$x][$y];
}

sub _rotate {
    my $s  = shift;
    my $in = $s->matrix;
    for my $rot (0 .. (($s->rotation / 90) % 4 - 1)) {
        my @out  = ();
        my $rows = scalar @$in;
        for my $row (0 .. $rows - 1) {
            $out[$row] = [map { $_->[$row] } reverse @$in];
        }

        #wantarray ? @out : \@out;
        $in = \@out;
    }
    __flatten($in);
}

sub __flatten {
    map { ref $_ ? __flatten(@{$_}) : $_ } @_;
}
1;
__END__

=encoding utf-8

=head1 NAME

RPi::UnicornHatHD - Use Pimoroni's Awesome Unicorn HAT HD in Perl

=head1 SYNOPSIS

	use RPi::UnicornHatHD;
	my $display = RPi::UnicornHatHD->new();
	while (1) { # Mini rave!
		$display->set_all(sprintf '#%06X', int rand(hex 'FFFFFF'));
		for (0 .. 100, reverse 0 .. 100) {
			$display->brightness($_ / 100);
			$display->show();
		}
	}

=head1 DESCRIPTION

Pimoroni's Unicorn HAT HD crams 256 RGB LEDs, in a 16x16 matrix, onto a single HAT for your Raspberry Pi. Use it for scrolling news or stock quotes. Mount it somewhere as a mood light. Build a binary clock. Uh. I don't know, you'll think of something.

=head1 METHODS

Use these to make pretty pictures.

=head2 C<new()>

	$display = RPi::UnicornHatHD->new();

Creates a new object representing your Unicorn Hat HD. Obviously.

=head2 C<brightness($b)>

	$display->brightness(.25); # For tinkering at 1a

Set the display brightness between C<0.0> and C<1.0>. The default is C<0.5>.

=head2 C<clear()>

	$display->clear;

Clears the display matrix.

This does not clear the display; it simply resets the 'canvas' for you.

=head2 C<get_pixel($x, $y)>

	my ($r, $g, $b) = $display->get_pixel(10, 15);

Returns the color this pixel will display.

=head2 C<off()>

	$display->off;

Clears the display matrix and immediately updates the Unicorn Hat HD.

This turns off all the pixels.

=head2 C<rotation($r)>

	$display->rotation(180);

Set the display rotation in degrees. Actual rotation will be snapped to the
nearest 90 degrees.

=head2 C<set_all($r, $g, $b)>

	$display->set_all(0xFF, 0, 0);
	$display->set_all('#FF0000');

Turns the entire display a single color.

Either...

	$r = Amount of red from 0 to 255
	$g = Amount of green from 0 to 255
	$b = Amount of blue from 0 to 255

...or...

	$h = Hex triplet from #000000 to #FFFFFF

=head2 C<set_pixel($x, $y, $r, $g, $b)>

	for my $x (1..10) {
		$display->set_pixel($x, 10, 1, 1, 1);
	}
	$display->set_pixel(0, 0, '#FFF000');

Set a single pixel to RGB color.

	$x = Horizontal position from 0 to 15
	$y = Vertical position from 0 to 15

...and either...

	$r = Amount of red from 0 to 255
	$g = Amount of green from 0 to 255
	$b = Amount of blue from 0 to 255

...or...

	$h = Hex triplet from #000000 to #FFFFFF

=head2 C<show()>

	$display->show;

Outputs the contents of the matrix buffer to your Unicorn HAT HD.

=head1 SEE ALSO

=over

=item * Buy one: L<http://shop.pimoroni.com/products/unicorn-hat-hd>

=item * GPIO Pinout: L<http://pinout.xyz/pinout/unicorn_hat_hd>

=item * Github: L<https://github.com/sanko/RPi-UnicornHatHD>

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut
