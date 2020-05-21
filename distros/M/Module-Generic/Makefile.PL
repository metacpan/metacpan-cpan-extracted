use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Module::Generic',
    AUTHOR              => 'Jacques Deguest <jack@deguest.jp>',
    VERSION_FROM        => 'lib/Module/Generic.pm',
    ABSTRACT_FROM       => 'lib/Module/Generic.pm',
    PL_FILES            => {},
    PREREQ_PM 			=> {
        'strict'		=> 0,
        'warnings'      => 0,
        'parent'		=> 0,
        'common::sense'	=> 0,
    	'overload'		=> '1.22',
    	'overloading'	=> '0.02',
    	'B'				=> 0,
    	'Clone'         => '0.43',
    	'Data::Dumper'	=> 0,
    	'Data::Printer'	=> 0,
    	'Devel::StackTrace' => 0,
    	'Class::Load'	=> '0.25',
    	'Exporter'		=> '5.73',
    	'JSON'          => '4.02',
    	'Number::Format' => '1.75',
    	'Nice::Try'     => 'v0.1.2',
    	'POSIX'         => '1.88',
    	'Regexp::Common'=> '2017060201',
    	'Scalar::Util'	=> '1.50',
    	'Tie::Hash'     => '1.05',
    	'Want'			=> '0.29',
    },
    TEST_REQUIRES =>
    {
        'Test::More'    => '1.302162',
        'Test::Pod'     => '1.52',
		'utf8'          => 0,
    },
    LICENSE				=> 'perl_5',
    MIN_PERL_VERSION	=> 5.6.0,
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Module-Generic-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? () : ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
        #    homepage    => undef,
            repository  => {
                url         => 'git@git.deguest.jp:jack/Module-Generic.git',
                web         => 'https://git.deguest.jp/jack/Module-Generic',
                type        => 'git',
            },
        #    bugtracker => {
        #        web         => undef,
        #    },
        },
    })),
);
