#! /usr/bin/env perl
use strict;
use warnings;
use FindBin;
use File::Spec::Functions 'catdir';
use Test::More;
use Log::Any::Adapter 'TAP';
use X11::GLX::DWIM;

use_ok( 'OpenGL::Sandbox::ResMan' ) or BAIL_OUT;

my $glx= X11::GLX::DWIM->new();
$glx->target({ pixmap => { width => 128, height => 128 }});
note 'GL Version '.$glx->glx_version;

my $res= OpenGL::Sandbox::ResMan->default_instance;
$res->resource_root_dir(catdir($FindBin::Bin, 'data'));
$res->font_config({
	default => 'squada',
	squada  => { filename => 'SquadaOne-Regular', face_size => 32 },
});
$res->tex_config({
	default => '8x8',
});

# Can't run font tests without a separate font module
# isa_ok( $res->font('default'), 'OpenGL::Sandbox::Font', 'load default font'  );
# is( $res->font('squada')->data, $res->font('default')->data, 'Empty is default' );
# is( $res->font('default')->ascender, 28, 'look up ascender' );

is( $res->tex_default_fmt, 'bgr', 'default pixel format' );

isa_ok( $res->tex('default'), 'OpenGL::Sandbox::Texture', 'load default tex' );
is( $res->tex('8x8'), $res->tex('default'), '8x8 is default' );
$res->tex('8x8')->load;
is( $res->tex('8x8')->width, 8, 'width=8' );

done_testing;
