use strict;
use warnings;
use ExtUtils::MakeMaker;

BEGIN {
   if ( $PDLA::Config{USE_POGL} ) {
      eval "use OpenGL $PDLA::Config{POGL_VERSION} qw()";
      if (!$@) {
         eval "use OpenGL::Config";
      }
   }
}

my @pack = (["openglq.pd", qw(OpenGLQ PDLA::Graphics::OpenGLQ)]);
my %hash = pdlpp_stdargs(@pack);

if ( $PDLA::Config{USE_POGL} ) {
   push @{$hash{LIBS}}, $OpenGL::Config->{LIBS};
   $hash{DEFINE} .= ' '.$OpenGL::Config->{DEFINE};
   $hash{INC} .= ' '.$OpenGL::Config->{INC};
   if($^O eq 'MSWin32') {
     $hash{LDFROM} .= ' '. $OpenGL::Config->{LDFROM};
     $hash{LDFROM} =~ s/\-lfreeglut//g;
   }
} else {
   warn "Graphics/TriD/OpenGLQ/Makefile.PL: will not compile bindings without Perl OpenGL\n\n";
   ## push @{$hash{LIBS}}, $PDLA::Config{OPENGL_LIBS};
   ## $hash{DEFINE} .= ' '.$PDLA::Config{OPENGL_DEFINE};
   ## $hash{INC} .= ' '.$PDLA::Config{OPENGL_INC};
}

${$hash{LIBS}}[0] .= ' -lm';

undef &MY::postamble; # suppress warning
*MY::postamble = sub {
	pdlpp_postamble(@pack);
};

WriteMakefile(%hash);
