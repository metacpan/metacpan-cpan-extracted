#!/usr/bin/perl
use Test::More tests => 2;
use_ok("OpenGL::Simple");
OpenGL::Simple->import(":all");
ok(GL_VERSION() > 0, "We have a version");
