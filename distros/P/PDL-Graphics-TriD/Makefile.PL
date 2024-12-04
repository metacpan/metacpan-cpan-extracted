use strict;
use warnings;
use ExtUtils::MakeMaker;
use PDL::Core::Dev;

WriteMakefile (
  NAME         => "PDL::Graphics::TriD",
  AUTHOR => 'PerlDL Developers <pdl-general@lists.sourceforge.net>',
  VERSION_FROM => 'TriD.pm',
  PM => {
    'TriD.pm' => '$(INST_LIBDIR)/TriD.pm',
    (map +($_ => '$(INST_LIBDIR)/'.$_), glob 'TriD/*.pm'),
    'DemoTriD1.pm' => '$(INST_LIB)/PDL/Demos/TriD1.pm',
    'DemoTriD2.pm' => '$(INST_LIB)/PDL/Demos/TriD2.pm',
    'DemoTriDGallery.pm' => '$(INST_LIB)/PDL/Demos/TriDGallery.pm',
  },
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => 0,
    'PDL' => '2.094',
    'OpenGL' => '0.70',
    'OpenGL::GLUT' => '0.72',
  },
  PREREQ_PM => {
    'PDL' => '2.094',
    'OpenGL' => '0.70',
    'OpenGL::GLUT' => '0.72',
  },
  TEST_REQUIRES => {
    'Test::More' => '0.88',
  },
);
