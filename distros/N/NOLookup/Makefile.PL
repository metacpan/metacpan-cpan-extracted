use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'NOLookup',
    VERSION_FROM    => 'lib/NOLookup.pm',
    MIN_PERL_VERSION => '5.18.0',

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 6.64,
    },

    PREREQ_PM => {
	'strict'       => 0,
	'warnings'     => 0,
	'vars'         => 0,
	'Data::Dumper' => 0,
	'Encode'       => 0,
	'IO::Socket'   => 0,
        'JSON'         => 0,
	'URI::Encode'  => 0,
	'WWW::Mechanize' => 0,
    },
    
    TEST_REQUIRES => {
        'Test::More' => 0,
    },

    
    );
