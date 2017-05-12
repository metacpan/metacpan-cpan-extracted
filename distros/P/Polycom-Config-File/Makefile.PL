use 5.008008;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME                  => 'Polycom::Config::File',
    VERSION_FROM          => 'lib/Polycom/Config/File.pm', # finds $VERSION
    PREREQ_PM             => {
        'Encode'                => 0,
        'File::Spec'            => 0,
        'IO::File'              => 0,
        'Test::More'            => 0,
        'XML::Twig'             => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM      => 'lib/Polycom/Config/File.pm', # retrieve abstract from module
       AUTHOR             => 'Zachary Blair <zblair@cpan.org>') : ()),
);
