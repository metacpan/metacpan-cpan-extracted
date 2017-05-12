use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Template::Like',
    VERSION_FROM      => 'lib/Template/Like.pm', # finds $VERSION
    PREREQ_PM         => {
      'File::Spec' => 0.8
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Template/Like.pm', # retrieve abstract from module
       AUTHOR         => 'Shinichiro Aska <askadna@cpan.org>') : ()),
);
