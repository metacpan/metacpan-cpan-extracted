#!perl -w
use strict;
use Config;
use Test::More tests => 2;
use OpenGL::Modern ':all';
use OpenGL::Modern::Helpers 'glGetVersion_p';

SKIP: {
    skip "glewInit not successful, skipping tests", 2 if glewCreateContext() or glewInit();    # GLEW_OK == 0
    skip "OpenGL 2 required at least for these tests", 2 if glGetVersion_p() < 2;

    # Set up a windowless OpenGL context?!
    my $id = glCreateShader( GL_VERTEX_SHADER );
    note "Got vertex shader $id, setting source";

    my $shader = <<SHADER;
int i;
provoke a syntax error
SHADER

    glShaderSource_p( $id, $shader );

    glCompileShader( $id );

    my $ok = "\0" x 4;
    my $pack_type = $Config{ptrsize} == 4 ? 'L' : 'Q';
    glGetShaderiv_c( $id, GL_COMPILE_STATUS, unpack( $pack_type, pack( 'p', $ok ) ) );
    $ok = unpack 'I', $ok;
    if ( $ok == GL_FALSE ) {
        pass "We recognize an invalid shader as invalid";

        my $bufsize = 1024 * 64;
        my $len     = "\0" x 4;
        my $buffer  = "\0" x $bufsize;
        glGetShaderInfoLog_c( $id, $bufsize, unpack( $pack_type, pack( 'p', $len ) ), $buffer );
        $len = unpack 'I', $len;
        my $log = substr $buffer, 0, $len;
        isnt $log, '', "We get some error message";

        note "Error message: $log";

    }
    else {
        fail "We recognize an invalid shader as valid";

    }

}

done_testing;
