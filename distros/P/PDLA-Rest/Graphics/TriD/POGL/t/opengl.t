# -*-perl-*-
BEGIN{
	  # Set perl to not try to resolve all symbols at startup
	  #   The default behavior causes some problems because 
	  #    opengl.pd builds an interface for all functions
	  #    defined in gl.h and glu.h even though they might not
	  #    actually be in the opengl libraries.
	  $ENV{'PERL_DL_NONLAZY'}=0;
}

# use PDLA::Graphics::OpenGL;

sub hasDISPLAY {
  return defined $ENV{DISPLAY} && $ENV{DISPLAY} !~ /^\s*$/;
}

use Test::More;

eval "use PDLA::Graphics::OpenGL::Perl::OpenGL";
plan skip_all => 'PDLA::Graphics::OpenGL::Perl::OpenGL not available' if $@;

plan tests => 1;
use_ok("OpenGL 0.6702", qw(:all));

#
# TODO: add runtime tests
#
