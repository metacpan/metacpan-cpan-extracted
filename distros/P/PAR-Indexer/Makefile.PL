use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    NAME              => 'PAR::Indexer',
    VERSION_FROM      => 'lib/PAR/Indexer.pm', # finds $VERSION
    LICENSE => 'perl',
    PREREQ_PM         => {
        'Cwd' => '0',
        'File::Spec' => '0',
        'File::Path' => '0',
        'PAR::Dist' => '0.31',
        'ExtUtils::Manifest' => '0',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/PAR/Indexer.pm', # retrieve abstract from module
       AUTHOR         => 'Steffen Müller <smueller@cpan.org>') : ()),
);
