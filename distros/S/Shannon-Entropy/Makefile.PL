use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Module::Metadata;

WriteMakefile(
    NAME             => 'Shannon::Entropy',
    AUTHOR           => q{Robert Acock <thisusedtobeanemail@gmail.com>},
    VERSION_FROM     => 'lib/Shannon/Entropy.pm',
    ABSTRACT_FROM    => 'lib/Shannon/Entropy.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
   		'Module::Metadata' => '1.000033',
	},
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
    	'Import::Export' => '0.08',
	},
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Shannon-Entropy-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        x_contributors => [
			"John Imrie (JGNI) <jgni\@cpan.org>"
		],
    },
    META_ADD => {
        provides => Module::Metadata->provides(version => '2', dir => 'lib'),
	}, 
);
