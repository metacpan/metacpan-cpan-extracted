#! /usr/bin/env perl
use strict;
use warnings;
use FindBin;
use Try::Tiny;
use Test::More;
use lib "$FindBin::Bin/lib";
use Log::Any::Adapter 'TAP';
use OpenGL::Sandbox qw/ make_context get_gl_errors /;
use OpenGL::Sandbox::Texture;

my $ctx= eval { make_context() };
plan skip_all => "Can't create an OpenGL context: $@"
	unless $ctx;

# Create tmp dir for this script
mkdir "$FindBin::Bin/tmp";
my $tmp= "$FindBin::Bin/tmp/$FindBin::Script";
$tmp =~ s/\.t$// or die "can't calc temp dir";
-d $tmp || mkdir $tmp or die "Can't create dir $tmp";

my $datadir= "$FindBin::Bin/data";

subtest load_rgb => \&test_load_rgb;
sub test_load_rgb {
	for my $dim (1, 2, 4, 16, 32, 64, 128) {
		subtest "dim=$dim" => sub {
			for my $alpha (0, 1) {
				# Write out RGBA texture
				my $fname= "$tmp/$dim-$alpha.rgb";
				open my $img1, '>', $fname or die "open($fname): $!";
				print $img1 chr(0x7F) x ($dim * $dim * ($alpha?4:3)) or die "print: $!";
				close $img1 or die "close: $!";
				# Load it as a texture
				my $tx= OpenGL::Sandbox::Texture->new(filename => $fname)->load;
				is_deeply( [get_gl_errors], [], 'no GL error' );
				is( $tx->width, $dim, "width=$dim" );
				is( $tx->height, $dim, "height=$dim" );
				is( $tx->pow2_size, $dim, "pow2_size=$dim" );
				ok( !$tx->mipmap, "no mipmaps" );
				is( !!$tx->has_alpha, !!$alpha, "has_alpha=$alpha" );
			}
		};
	}
};

subtest load_png => \&test_load_png;
sub test_load_png {
	my @tests= (
		[ '8x8.png', 8, 8, 8, 0, 8, 8 ],
		[ '14x7-rgba.png', 16, 16, 16, 1, 14, 7 ]
	);
	for (@tests) {
		my ($fname, $width, $height, $pow2, $has_alpha, $src_w, $src_h)= @$_;
		subtest $fname => sub {
			my $tx= OpenGL::Sandbox::Texture->new(filename => "$datadir/tex/$fname")->load;
			is_deeply( [get_gl_errors], [], 'no GL error' );
			is( $tx->width, $width, 'width' );
			is( $tx->height, $height, 'height' );
			is( $tx->pow2_size, $pow2, 'pow2_size' );
			is( $tx->has_alpha, $has_alpha, 'alpha' );
			is( $tx->src_width, $src_w, 'src_width' );
			is( $tx->src_height, $src_h, 'src_height' );
			
			OpenGL::Sandbox::Texture::convert_png("$datadir/tex/$fname", "$tmp/$fname.rgb");
			my $tx2= OpenGL::Sandbox::Texture->new(filename => "$tmp/$fname.rgb")->load;
			is_deeply( [get_gl_errors], [], 'no GL error' );
			is( $tx2->width, $tx->width, 'width after convert to rgb' );
		};
	}
}

done_testing;
