use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'MogileFS::Plugin::FileRefs',
    VERSION_FROM      => 'lib/MogileFS/Plugin/FileRefs.pm', # finds $VERSION
    PREREQ_PM         => {
        "MogileFS::Server" => 0,
        "Test::More" => 0,
        "Text::Exception" => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ? (    ## Add these new keywords supported since 5.005
        ABSTRACT_FROM  => 'lib/MogileFS/Plugin/FileRefs.pm', # retrieve abstract from module
        AUTHOR         => 'Dave Lambley <davel@state51.co.uk>',
        META_MERGE     => {
            resources  => {
                repository => 'https://github.com/davel/MogileFS-Plugin-FileRefs',
                homepage   => 'https://metacpan.org/release/MogileFS-Plugin-FileRefs',
            },
        },
    ) : ()),
);
