#! /usr/bin/env perl
use strict;
use warnings;
use FindBin;
use Try::Tiny;
use Test::More;
use lib "$FindBin::Bin/lib";
use Log::Any::Adapter 'TAP';
use OpenGL::Sandbox qw/ make_context log_gl_errors GL_RGB /;
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
				ok( !log_gl_errors, 'No GL errors' );
				is( $tx->width, $dim, "width=$dim" );
				is( $tx->height, $dim, "height=$dim" );
				ok( !$tx->mipmap, "no mipmaps" );
				is( !!$tx->has_alpha, !!$alpha, "has_alpha=$alpha" );
			}
		};
	}
};

subtest load_png => \&test_load_png;
sub test_load_png {
	my @tests= (
		[ '8x8.png', 8, 8, 0, 8, 8 ],
		[ '14x7-rgba.png', 14, 7, 1, 14, 7 ]
	);
	for (@tests) {
		my ($fname, $width, $height, $has_alpha, $src_w, $src_h)= @$_;
		subtest $fname => sub {
			my $tx= OpenGL::Sandbox::Texture->new(filename => "$datadir/tex/$fname")->load;
			ok( !log_gl_errors, 'No GL errors' );
			is( $tx->width, $width, 'width' );
			is( $tx->height, $height, 'height' );
			is( $tx->has_alpha, $has_alpha, 'alpha' );
			is( $tx->src_width, $src_w, 'src_width' );
			is( $tx->src_height, $src_h, 'src_height' );
			
			if ($width == $height) {
				OpenGL::Sandbox::Texture::convert_png("$datadir/tex/$fname", "$tmp/$fname.rgb");
				my $tx2= OpenGL::Sandbox::Texture->new(filename => "$tmp/$fname.rgb")->load;
				ok( !log_gl_errors, 'No GL errors' );
				is( $tx2->$_, $tx->$_, "$_ after convert to rgb" )
					for 'width', 'height';
			}
		};
	}
}

subtest init_no_load => \&test_init_no_load;
sub test_init_no_load {
	my @tests= (
		{ name => 'plain_256_square', width => 256, height => 256, internal_format => GL_RGB }
	);
	for (@tests) {
		my $tx= new_ok( 'OpenGL::Sandbox::Texture', [$_], $_->{name} );
		$tx->load(data => undef);
		ok( !log_gl_errors, 'No GL errors' );
	}
}

subtest init_manual => \&test_init_manual;
sub test_init_manual {
	my @tests= (
		[ { name => 'plan_32_square' }, { width => 32, height => 32, format => GL_RGB, data => \("x"x(32*32*3)) } ],
	);
	for (@tests) {
		my ($ctor, $call)= @$_;
		my $tx= new_ok( 'OpenGL::Sandbox::Texture', [$ctor], $ctor->{name} );
		$tx->load($call);
		is( $tx->width, $call->{width}, 'width updated' ) if $call->{width};
		is( $tx->height, $call->{height}, 'height updated' ) if $call->{height};
		is( $tx->loaded, 1, 'marked as loaded' );
		ok( !log_gl_errors, 'No GL errors' );
	}
}

done_testing;
