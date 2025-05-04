use strict;
use warnings;
use Test::More;
use OpenGL::Modern qw(
  :glewfunctions
  glGetString
  GLEW_OK GL_VERSION GL_TRUE GL_FALSE
);

my $gCC_status = glewCreateContext(); # returns GL_TRUE or GL_FALSE
ok $gCC_status == GL_TRUE || $gCC_status == GL_FALSE, "glewCreateContext";

if ($gCC_status == GLEW_OK) {
  my $gI_status = done_glewInit() ? GLEW_OK() : glewInit();                           # returns GLEW_OK or ???
  is $gI_status, GLEW_OK(), "glewInit";
  if ($gI_status == GLEW_OK()) {
    isnt '', glGetString( GL_VERSION ), 'GL_VERSION';
  }
}

done_testing;
