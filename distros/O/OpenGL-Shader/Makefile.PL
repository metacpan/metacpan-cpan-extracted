use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
  NAME          => 'OpenGL::Shader',
  DISTNAME      => 'OpenGL-Shader',
  VERSION_FROM  => 'Shader.pm',
  PREREQ_PM     => {OpenGL=>'0.56'},
  dist          => {COMPRESS => 'gzip', SUFFIX => 'gz'},
  ($] >= 5.005 ?
    (ABSTRACT => 'OpenGL Shader Utility Module',
     AUTHOR   => 'Bob "grafman" Free (grafman@grafcomp.com)') : ()),
);
