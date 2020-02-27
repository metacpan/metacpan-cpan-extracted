use 5.026001;
use ExtUtils::MakeMaker;

use Devel::CheckLib;

check_lib_or_exit(
    lib			=> 'open62541',
    header		=> 'open62541/types.h',
    libpath		=> '/usr/local/lib',
    incpath		=> '/usr/local/include',
);

WriteMakefile(
    NAME		=> 'OPCUA::Open62541',
    VERSION_FROM	=> 'lib/OPCUA/Open62541.pm',
    CONFIGURE_REQUIRES	=> {
	'Devel::CheckLib'	=> 0,
    },
    PREREQ_PM		=> {},
    ABSTRACT_FROM	=> 'lib/OPCUA/Open62541.pm',
    AUTHOR		=> [
	'Alexander Bluhm <bluhm@genua.de>',
	'Anton Borowka',
	'Arne Becker',
	'Marvin Knoblauch <mknob@genua.de>',
    ],
    LICENSE		=> 'perl_5',
    LIBS		=> ['-L/usr/local/lib -lopen62541'],
    DEFINE		=> '',
    INC			=> '-I. -I/usr/local/include '.
	'-Wall -Wpointer-arith -Wuninitialized -Wstrict-prototypes '.
	'-Wmissing-prototypes -Wunused -Wsign-compare -Wshadow',
    SIGN		=> 1,
    TEST_REQUIRES	=> {
	'Test::Exception'	=> 0,
	'Test::LeakTrace'	=> 0,
	'Test::NoWarnings'	=> 0,
	'Test::TCP'		=> 0,
	'Test::Perl::Critic'	=> 0,
	'Test::Pod'		=> '1.00',
	'Test::Requires'	=> 0,
	'Test::Warn'		=> 0,
    },
);
