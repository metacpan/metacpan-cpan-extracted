#! /usr/bin/perl

use strict;
use warnings;
use Test::More;
use OpenGL::Modern ':all';
use OpenGL::Modern::Helpers 'glGetVersion_p';
use Capture::Tiny 'capture';

SKIP: {
    plan skip_all => "glewContext did not succeed, skipping live tests"
      if glewCreateContext() != GLEW_OK;    # returns GL_TRUE or GL_FALSE

    my $gI_status = ( done_glewInit() ) ? GLEW_OK() : glewInit();    # returns GLEW_OK or ???
    plan skip_all => "glewInit did not succeed, skipping live tests"
      if $gI_status != GLEW_OK;

    glClear GL_COLOR;
    pass "didn't crash yet";

    my ( $out, $err ) = capture {
        eval { $@ = undef; glpCheckErrors };
    };
    like $err, qr/OpenGL error: 1281/,          "got expected errors";
    like $@,   qr/1 OpenGL errors encountered/, "can check for errors manually";

    eval { $@ = undef; glpSetAutoCheckErrors 3 };
    is $@, "Usage: glpSetAutoCheckErrors(1|0)\n", "glpSetAutoCheckErrors only accepts 2 values";

    glpSetAutoCheckErrors 1;
    ( $out, $err ) = capture {
        eval { $@ = undef; glClear GL_COLOR };
    };
    like $err, qr/OpenGL error: 1281/,          "got expected errors";
    like $@,   qr/1 OpenGL errors encountered/, "errors cause crashes now";

    glpSetAutoCheckErrors 0;
    glClear GL_COLOR;
    pass "crashes are gone again";

    ( $out, $err ) = capture {
        eval { $@ = undef; glpCheckErrors };
    };
    like $err, qr/OpenGL error: 1281/,          "got expected errors";
    like $@,   qr/1 OpenGL errors encountered/, "but we can still check for errors manually";

    done_testing;
}
