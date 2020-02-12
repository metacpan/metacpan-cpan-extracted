use 5.030001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'OPCUA::Open62541',
    VERSION_FROM      => 'lib/OPCUA/Open62541.pm',
    PREREQ_PM         => {},
    ABSTRACT_FROM     => 'lib/OPCUA/Open62541.pm',
    AUTHOR            => 'Alexander Bluhm <bluhm@genua.de>',
    LICENSE           => 'perl_5',
    LIBS              => ['-L/usr/local/lib -lopen62541'],
    DEFINE            => '',
    INC               => '-I. -I/usr/local/include',
    SIGN              => 1,
    TEST_REQUIRES     => {
	'Test::LeakTrace'	=> 0,
	'Test::NoWarnings'	=> 0,
	'Test::Warn'		=> 0,
    },
);
