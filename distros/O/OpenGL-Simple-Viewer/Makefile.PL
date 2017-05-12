use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'OpenGL::Simple::Viewer',
    'VERSION_FROM'	=> 'Viewer.pm', # finds $VERSION
    'PREREQ_PM'		=> {
                                OpenGL::Simple => 0,
                                OpenGL::Simple::GLUT => 0,
                                Math::Quaternion => 0,
                            },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Viewer.pm', # retrieve abstract from module
       AUTHOR     => 'Jonathan Chin <jon-opengl-simple-viewer@earth.li>') : ()),
);
