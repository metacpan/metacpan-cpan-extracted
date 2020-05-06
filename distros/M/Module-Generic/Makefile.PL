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
    	'Data::Dumper'	=> 0,
    	'Data::Printer'	=> 0,
    	'Devel::StackTrace' => 0,
    	'Class::Load'	=> '0.25',
    	'Exporter'		=> '5.73',
    	'Number::Format' => '1.75',
    	'Scalar::Util'	=> '1.50',
    	'Text::Number'	=> 0,
    	'Tie::Hash'     => '1.05',
    	'TryCatch'		=> '1.003002',
    	'Want'			=> '0.29',
    },
    TEST_REQUIRES =>
    {
		'Test::Simple' => 0,
		'Test::Pod'	=> 0,
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
                url         => 'git@github.com:jackdeguest/Module-Generic.git',
                web         => 'https://github.com/jackdeguest/Module-Generic',
                type        => 'git',
            },
        #    bugtracker => {
        #        web         => undef,
        #    },
        },
    })),
);
