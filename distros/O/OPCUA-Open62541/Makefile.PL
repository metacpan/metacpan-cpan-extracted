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
    function		=> "UA_Server_setAdminSessionContext(NULL, NULL);",
    not_execute		=> 1,
    lib			=> 'open62541',
    header		=> 'open62541/server.h',
    libpath		=> '/usr/local/lib',
    incpath		=> '/usr/local/include',
) and push @have, uc('UA_Server_setAdminSessionContext');
check_lib(
    function		=> "
	UA_NodeId nodeId;
	UA_Server_readContainsNoLoops(NULL, nodeId, NULL);",
    not_execute		=> 1,
    lib			=> 'open62541',
    header		=> 'open62541/server.h',
    libpath		=> '/usr/local/lib',
    incpath		=> '/usr/local/include',
) and push @have, uc('UA_Server_readContainsNoLoops');
check_lib(
    function		=> "UA_Client_getState(NULL, NULL, NULL, NULL);",
    not_execute		=> 1,
    lib			=> 'open62541',
    header		=> 'open62541/client.h',
    libpath		=> '/usr/local/lib',
    incpath		=> '/usr/local/include',
) and push @have, uc('UA_Client_getState_3');
check_lib(
    function		=> "UA_Client_connectAsync(NULL, NULL);",
    not_execute		=> 1,
    lib			=> 'open62541',
    header		=> 'open62541/client.h',
    libpath		=> '/usr/local/lib',
    incpath		=> '/usr/local/include',
) and push @have, uc('UA_Client_connectAsync');
check_lib(
    function		=> "
	UA_NodeId nodeId;
	UA_Client_readNodeIdAttribute_async(NULL, nodeId, NULL, NULL, NULL);",
    not_execute		=> 1,
    lib			=> 'open62541',
    header		=> 'open62541/client.h',
    libpath		=> '/usr/local/lib',
    incpath		=> '/usr/local/include',
) and push @have, uc('UA_Client_readNodeIdAttribute_async');
check_lib(
    function		=> "(UA_ClientAsyncOperationCallback)NULL;",
    not_execute		=> 1,
    lib			=> 'open62541',
    header		=> 'open62541/client_highlevel_async.h',
    libpath		=> '/usr/local/lib',
    incpath		=> '/usr/local/include',
) and push @have, uc('UA_ClientAsyncOperationCallback');
check_lib(
    function		=> "
	UA_ClientAsyncReadValueAttributeCallback callback;
	UA_DataValue dataValue;
	callback(NULL, NULL, 0, 0, &dataValue);",
    not_execute		=> 1,
    lib			=> 'open62541',
    header		=> 'open62541/client_highlevel_async.h',
    libpath		=> '/usr/local/lib',
    incpath		=> '/usr/local/include',
) and push @have, uc('UA_ClientAsyncReadValueAttributeCallback_DataValue');
check_lib(
    function		=> "
	UA_ClientAsyncReadValueAttributeCallback callback;
	UA_Variant variant;
	callback(NULL, NULL, 0, &variant);",
    not_execute		=> 1,
    lib			=> 'open62541',
    header		=> 'open62541/client_highlevel_async.h',
    libpath		=> '/usr/local/lib',
    incpath		=> '/usr/local/include',
) and push @have, uc('UA_ClientAsyncReadValueAttributeCallback_Variant');
check_lib(
    function		=> "UA_ServerConfig_setCustomHostname(NULL, NULL);",
    not_execute		=> 1,
    lib			=> 'open62541',
    header		=> 'open62541/client.h',
    libpath		=> '/usr/local/lib',
    incpath		=> '/usr/local/include',
) and push @have, uc('UA_ServerConfig_setCustomHostname');
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
check_lib(
    function		=> "UA_ClientState clientState;",
    not_execute		=> 1,
    lib			=> 'open62541',
    header		=> 'open62541/client.h',
    libpath		=> '/usr/local/lib',
    incpath		=> '/usr/local/include',
) and push @have, uc('UA_ClientState');
check_lib(
    function		=> "
	UA_SecureChannelState channelState;
	channelState = UA_SECURECHANNELSTATE_FRESH;",
    not_execute		=> 1,
    lib			=> 'open62541',
    header		=> 'open62541/client.h',
    libpath		=> '/usr/local/lib',
    incpath		=> '/usr/local/include',
) and push @have, uc('UA_SecureChannelState_Fresh');
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
    INC			=> '-I. -I/usr/local/include '.
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
	'Test::Deep'		=> 0,
	'Test::EOL'		=> 0,
	'Test::Exception'	=> 0,
	'Test::LeakTrace'	=> 0,
	'Test::NoWarnings'	=> 0,
	'Test::TCP'		=> 0,
	'Test::Perl::Critic'	=> 0,
	'Test::Pod'		=> '1.00',
	'Test::Requires'	=> 0,
	'Test::Strict'		=> 0,
	'Test::Warn'		=> 0,
	'YAML::Tiny'		=> 0,
    },
    clean		=> {
	FILES => [ "*.log", "*.utf8", "*.yaml", "assertlibFPDc52aN.c" ],
    },
);
