use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    NAME              => 'PAR::Repository::Client',
    VERSION_FROM      => 'lib/PAR/Repository/Client.pm', # finds $VERSION
    LICENSE => 'perl',
    PREREQ_PM         => {
#'perl'      => '5.6',
        'Archive::Zip'            => '0',
        'DBM::Deep'               => '1.0012',
        'File::Spec'              => '0',
        'LWP::Simple'             => '0',
        'PAR'                     => '0.987_01',
        'PAR::Dist'               => '0.44',
        'PAR::Repository::Query'  => '0.12',
        'version'                 => '0.50',
        'YAML::Tiny'              => '0',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/PAR/Repository/Client.pm', # retrieve abstract from module
       AUTHOR         => 'Steffen Mueller <smueller@cpan.org>') : ()),
);
