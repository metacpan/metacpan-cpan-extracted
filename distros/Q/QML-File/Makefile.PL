use 5.008008;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'QML::File',
    VERSION_FROM      => 'lib/QML/File.pm', # finds $VERSION
    PREREQ_PM         => { 'Test::More' => 0, 'Class::Accessor' => 0 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/QML/File.pm', # retrieve abstract from module
       AUTHOR         => 'Zachary Blair <zblair@cpan.org>') : ()),
);
