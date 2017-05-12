use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    NAME              => 'PAR::Repository',
    VERSION_FROM      => 'lib/PAR/Repository.pm', # finds $VERSION
    LICENSE => 'perl',
    PREREQ_PM         => {
#'perl'      => '5.6',
        'DBM::Deep' => '1.0012',
        'File::Spec' => '0',
        'File::Path' => '0',
        'File::Temp' => '0.19', # EXLOCK
        'File::Copy' => '0',
        'Archive::Zip' => '0',
        'PAR::Dist' => '0.44',
        'YAML::Syck' => '0.62',
        'version' => '0.50',
        'Pod::Text' => '0',
        'ExtUtils::Manifest' => '0',
        'PAR::Repository::Query' => '0.12',
        'PAR::Indexer' => '0.91',
        'Digest::MD5' => '0',
    }, # e.g., Module::Name => 1.1
    EXE_FILES => [
      'bin/parrepo',
    ],
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/PAR/Repository.pm', # retrieve abstract from module
       AUTHOR         => 'Steffen Müller <smueller@cpan.org>') : ()),
);
