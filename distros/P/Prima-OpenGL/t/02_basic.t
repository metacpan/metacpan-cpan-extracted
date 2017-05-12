#! /usr/bin/perl

use strict;
use warnings;
use Test::More;
use Prima::noX11;
use Prima::OpenGL;

eval 'use Test::Pod::Coverage';
my $xerror = Prima::XOpenDisplay;
plan skip_all => $xerror if defined $xerror;

my $tests = 2;
plan tests => $tests;
$::application = Prima::Application-> new;
$::application-> begin_paint;

my $ctx = Prima::OpenGL::context_create($::application, {});
unless ( ok( $ctx, 'create_context')) {
	my $err = Prima::OpenGL::last_error();
	diag $err;
	SKIP: { skip $err, $tests - 1 };
	exit;
}

ok(Prima::OpenGL::context_make_current($ctx));

Prima::OpenGL::context_destroy($ctx);
$::application-> end_paint;
