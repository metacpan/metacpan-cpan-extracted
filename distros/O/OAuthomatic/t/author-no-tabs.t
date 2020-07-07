
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/OAuthomatic.pm',
    'lib/OAuthomatic/Caller.pm',
    'lib/OAuthomatic/Config.pm',
    'lib/OAuthomatic/Error.pm',
    'lib/OAuthomatic/Internal/MicroWeb.pm',
    'lib/OAuthomatic/Internal/MicroWebSrv.pm',
    'lib/OAuthomatic/Internal/UsageGuard.pm',
    'lib/OAuthomatic/Internal/Util.pm',
    'lib/OAuthomatic/OAuthInteraction.pm',
    'lib/OAuthomatic/OAuthInteraction/ViaMicroWeb.pm',
    'lib/OAuthomatic/SecretStorage.pm',
    'lib/OAuthomatic/SecretStorage/Keyring.pm',
    'lib/OAuthomatic/Server.pm',
    'lib/OAuthomatic/ServerDef.pm',
    'lib/OAuthomatic/ServerDef/BitBucket.pm',
    'lib/OAuthomatic/ServerDef/LinkedIn.pm',
    'lib/OAuthomatic/Types.pm',
    'lib/OAuthomatic/UserInteraction.pm',
    'lib/OAuthomatic/UserInteraction/ConsolePrompts.pm',
    'lib/OAuthomatic/UserInteraction/ViaMicroWeb.pm',
    'scripts/oauthomatic_forget_tokens.pl',
    'scripts/oauthomatic_predefined_servers.pl',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-compile/lib_OAuthomatic_Caller_pm.t',
    't/00-compile/lib_OAuthomatic_Config_pm.t',
    't/00-compile/lib_OAuthomatic_Error_pm.t',
    't/00-compile/lib_OAuthomatic_Internal_MicroWebSrv_pm.t',
    't/00-compile/lib_OAuthomatic_Internal_MicroWeb_pm.t',
    't/00-compile/lib_OAuthomatic_Internal_UsageGuard_pm.t',
    't/00-compile/lib_OAuthomatic_Internal_Util_pm.t',
    't/00-compile/lib_OAuthomatic_OAuthInteraction_ViaMicroWeb_pm.t',
    't/00-compile/lib_OAuthomatic_OAuthInteraction_pm.t',
    't/00-compile/lib_OAuthomatic_SecretStorage_Keyring_pm.t',
    't/00-compile/lib_OAuthomatic_SecretStorage_pm.t',
    't/00-compile/lib_OAuthomatic_ServerDef_BitBucket_pm.t',
    't/00-compile/lib_OAuthomatic_ServerDef_LinkedIn_pm.t',
    't/00-compile/lib_OAuthomatic_ServerDef_pm.t',
    't/00-compile/lib_OAuthomatic_Server_pm.t',
    't/00-compile/lib_OAuthomatic_Types_pm.t',
    't/00-compile/lib_OAuthomatic_UserInteraction_ConsolePrompts_pm.t',
    't/00-compile/lib_OAuthomatic_UserInteraction_ViaMicroWeb_pm.t',
    't/00-compile/lib_OAuthomatic_UserInteraction_pm.t',
    't/00-compile/lib_OAuthomatic_pm.t',
    't/00-load.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/21-util-parse.t',
    't/22-util-fill.t',
    't/31-nonce.t',
    't/41-types-client_cred.t',
    't/42-types-token-cred.t',
    't/43-types-temp-cred.t',
    't/44-types-verifier-cred.t',
    't/ToDo.txt'
);

notabs_ok($_) foreach @files;
done_testing;
