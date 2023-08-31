use strict;
use warnings;

use 5.026001;
use ExtUtils::MakeMaker;

use Devel::CheckLib;

check_lib_or_exit(
    lib			=> 'open62541',
    header		=> 'open62541/types.h',
    libpath		=> '/usr/local/lib',
    incpath		=> '/usr/local/include',
);

my @have;
check_lib(
    function		=> "
	UA_ServerConfig serverConfig;
	(void)serverConfig.customHostname;",
    not_execute		=> 1,
    lib			=> 'open62541',
    header		=> 'open62541/server.h',
    libpath		=> '/usr/local/lib',
    incpath		=> '/usr/local/include',
) and push @have, uc('UA_ServerConfig_customHostname');
check_lib(
    function		=> "
	UA_ServerConfig serverConfig;
	(void)serverConfig.serverUrls;",
    not_execute		=> 1,
    lib			=> 'open62541',
    header		=> 'open62541/server.h',
    libpath		=> '/usr/local/lib',
    incpath		=> '/usr/local/include',
) and push @have, uc('UA_ServerConfig_serverUrls');
check_lib(
    function		=> "
	UA_ServerConfig serverConfig;
	(void)UA_AccessControl_defaultWithLoginCallback(&serverConfig,
	    0, NULL, NULL, 0, NULL, NULL, NULL);",
    not_execute		=> 1,
    lib			=> 'open62541',
    header		=> 'open62541/plugin/accesscontrol_default.h',
    libpath		=> '/usr/local/lib',
    incpath		=> '/usr/local/include',
) and push @have, uc('UA_AccessControl_defaultWithLoginCallback');
check_lib(
    function		=> 'crypt_checkpass("", "");',
    lib			=> 'c',
    header		=> [qw(pwd.h unistd.h)],
) and push @have, uc('crypt_checkpass');
check_lib(
    function		=> "
	UA_ClientConfig clientConfig;
	(void)clientConfig.applicationUri;",
    not_execute		=> 1,
    lib			=> 'open62541',
    header		=> 'open62541/client.h',
    libpath		=> '/usr/local/lib',
    incpath		=> '/usr/local/include',
) and push @have, uc('UA_ClientConfig_applicationUri');
check_lib(
    function		=> "
	UA_SessionlessInvokeRequestType requestType;
	(void)requestType.urisVersionSize;",
    not_execute		=> 1,
    lib			=> 'open62541',
    header		=> 'open62541/client.h',
    libpath		=> '/usr/local/lib',
    incpath		=> '/usr/local/include',
) and push @have, uc('UA_SessionlessInvokeRequestType_urisVersionSize');
check_lib(
    function		=> "
	UA_ProgramDiagnostic2DataType dataType;
	UA_StatusResult statusResult;
	statusResult = dataType.lastMethodReturnStatus;",
    not_execute		=> 1,
    lib			=> 'open62541',
    header		=> 'open62541/client.h',
    libpath		=> '/usr/local/lib',
    incpath		=> '/usr/local/include',
) and push @have, uc('UA_ProgramDiagnostic2DataType_StatusResult');
my @defines = map { "-DHAVE_$_=1" } @have;

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
    INC			=>
	'-I. -I/usr/local/include '.
	"@defines ".
	'-Wall -Wpointer-arith -Wuninitialized -Wstrict-prototypes '.
	'-Wmissing-prototypes -Wunused -Wsign-compare -Wshadow '.
	'-Wno-pointer-sign',
    META_MERGE		=> {
	'meta-spec' => { version => 2 },
	resources => {
	    repository => {
		type => 'git',
		url  => 'git://github.com/bluhm/p5-opcua-open62541.git',
		web  => 'https://github.com/bluhm/p5-opcua-open62541/',
	    },
	},
    },
    #OPTIMIZE		=> '-g -O0 -DDEBUG',
    SIGN		=> 1,
    TEST_REQUIRES	=> {
	'IO::Socket::SSL::Utils'	=> 0,
	'MIME::Base64'			=> 0,
	'Socket6'			=> 0,
	'Test::Deep'			=> 0,
	'Test::EOL'			=> 0,
	'Test::Exception'		=> 0,
	'Test::LeakTrace'		=> 0,
	'Test::NoWarnings'		=> 0,
	'Test::Perl::Critic'		=> 0,
	'Test::Pod'			=> '1.00',
	'Test::Requires'		=> 0,
	'Test::Strict'			=> 0,
	'Test::TCP'			=> 0,
	'Test::Warn'			=> 0,
	'YAML::Tiny'			=> 0,
    },
    clean		=> {
	FILES => [ "*.log", "*.utf8", "*.yaml", "assertlibFPDc52aN.c" ],
    },
);
