#! /usr/bin/perl

use strict;
use warnings;
use Test::More;
use Prima::noX11;
use Prima::OpenGL;

eval 'use Test::Pod::Coverage';
my $xerror = Prima::XOpenDisplay;
plan skip_all => $xerror if defined $xerror;

my $tests = 3;
plan tests => $tests;
$::application = Prima::Application-> new;
my $w = Prima::Window->new;
$w-> begin_paint;

my $ctx = Prima::OpenGL::context_create($w, {});
unless ( ok( $ctx, 'create_context')) {
	my $err = Prima::OpenGL::last_error();
	diag $err;
	SKIP: { skip $err, $tests - 1 };
	exit;
}

my $direct = Prima::OpenGL::is_direct($ctx);
ok( 1, "direct: $direct");
ok(Prima::OpenGL::context_make_current($ctx));

Prima::OpenGL::context_destroy($ctx);
$w-> end_paint;
