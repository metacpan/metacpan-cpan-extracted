#! /usr/bin/perl

use strict;
use warnings;
use Test::More;
use OpenGL::Modern ':all';
use OpenGL::Modern::Helpers 'glGetVersion_p';

SKIP: {
    plan skip_all => "glewContext did not succeed, skipping live tests"
      if glewCreateContext() != GLEW_OK;    # returns GL_TRUE or GL_FALSE

    my $gI_status = ( done_glewInit() ) ? GLEW_OK() : glewInit();    # returns GLEW_OK or ???
    plan skip_all => "glewInit did not succeed, skipping live tests"
      if $gI_status != GLEW_OK;

    my @version_pairs = (
        [ GLEW_VERSION_1_1, 1.1 ],
        [ GLEW_VERSION_1_2, 1.2 ],
        [ GLEW_VERSION_1_3, 1.3 ],
        [ GLEW_VERSION_1_4, 1.4 ],
        [ GLEW_VERSION_1_5, 1.5 ],
        [ GLEW_VERSION_2_0, 2.0 ],
        [ GLEW_VERSION_2_1, 2.1 ],
        [ GLEW_VERSION_3_0, 3.0 ],
        [ GLEW_VERSION_3_1, 3.1 ],
        [ GLEW_VERSION_3_2, 3.2 ],
        [ GLEW_VERSION_3_3, 3.3 ],
        [ GLEW_VERSION_4_0, 4.0 ],
        [ GLEW_VERSION_4_1, 4.1 ],
        [ GLEW_VERSION_4_2, 4.2 ],
        [ GLEW_VERSION_4_3, 4.3 ],
        [ GLEW_VERSION_4_4, 4.4 ],
        [ GLEW_VERSION_4_5, 4.5 ],
    );

    my $version = glGetVersion_p;
    $_->[2] = $version >= $_->[1] ? 1 : 0 for @version_pairs;

    local $TODO = "we're not quite sure yet what these do";

    # presume all calls up to the gl version return 1
    is $_->[0], 1, sprintf "glew version %.1f reported as 1 for $version", $_->[1]    #
      for grep $_->[1] <= $version, @version_pairs;

    # ensure at least the results of functions above current version are defined
    ok defined( $_->[0] ), sprintf "glew version %.1f defined (value = $_->[0]) for $version", $_->[1]    #
      for grep $_->[1] > $version, @version_pairs;

    done_testing;
}
