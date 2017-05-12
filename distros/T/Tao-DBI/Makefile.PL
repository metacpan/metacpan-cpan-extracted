
use 5.006;
use ExtUtils::MakeMaker;

my $EUMM_VERSION = eval $ExtUtils::MakeMaker::VERSION;

WriteMakefile(
    NAME              => 'Tao::DBI',
    VERSION_FROM      => 'lib/Tao/DBI.pm', # finds $VERSION
    PREREQ_PM         => {
        DBI               => 1,
    }, 
    ($] >= 5.005 ? (
       ABSTRACT_FROM  => 'lib/Tao/DBI.pm', # retrieve abstract from module
       AUTHOR         => 'Adriano R. Ferreira <ferreira@cpan.org>',
    ) : ()),
    ($EUMM_VERSION >= 6.31 ? (
       LICENSE => 'perl',
    ) : ()),
    ($EUMM_VERSION > 6.4501 ? (
        META_MERGE => {
            'meta-spec' => { version => 2 },
            resources => {
                repository => {
                    type => 'git',
                    url => 'git://github.com/aferreira/cpan-Tao-DBI.git',
                    web => 'https://github.com/aferreira/cpan-Tao-DBI',
                }
            },
            prereqs => {
                test => {
		    requires => {
                        'DBD::SQlite'  => 0,
                        'Data::Dumper' => 0,
                        'YAML'         => 0,
                    },
                }
            },
        },
    ) : ()),
);
