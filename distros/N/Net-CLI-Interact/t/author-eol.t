
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Net/CLI/Interact.pm',
    'lib/Net/CLI/Interact/Action.pm',
    'lib/Net/CLI/Interact/ActionSet.pm',
    'lib/Net/CLI/Interact/Logger.pm',
    'lib/Net/CLI/Interact/Phrasebook.pm',
    'lib/Net/CLI/Interact/Role/Engine.pm',
    'lib/Net/CLI/Interact/Role/FindMatch.pm',
    'lib/Net/CLI/Interact/Role/Iterator.pm',
    'lib/Net/CLI/Interact/Role/Prompt.pm',
    'lib/Net/CLI/Interact/Transport/Base.pm',
    'lib/Net/CLI/Interact/Transport/Loopback.pm',
    'lib/Net/CLI/Interact/Transport/Net_OpenSSH.pm',
    'lib/Net/CLI/Interact/Transport/Platform/Unix.pm',
    'lib/Net/CLI/Interact/Transport/Platform/Win32.pm',
    'lib/Net/CLI/Interact/Transport/Role/ConnectCore.pm',
    'lib/Net/CLI/Interact/Transport/Role/StripControlChars.pm',
    'lib/Net/CLI/Interact/Transport/SSH.pm',
    'lib/Net/CLI/Interact/Transport/Serial.pm',
    'lib/Net/CLI/Interact/Transport/Telnet.pm',
    'lib/Net/CLI/Interact/Transport/Wrapper/Base.pm',
    'lib/Net/CLI/Interact/Transport/Wrapper/IPC_Run.pm',
    'lib/Net/CLI/Interact/Transport/Wrapper/Net_Telnet.pm',
    't/00-compile.t',
    't/10_construct.t',
    't/author-10_route_server.t',
    't/author-11_ssh_unknown_host.t',
    't/author-12_ssh_no_route.t',
    't/author-13_ssh_timeout.t',
    't/author-critic.t',
    't/author-distmeta.t',
    't/author-eol.t',
    't/author-minimum-version.t',
    't/author-mojibake.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-linkcheck.t',
    't/author-pod-syntax.t',
    't/author-portability.t',
    't/author-synopsis.t',
    't/author-test-version.t',
    't/perlcriticrc',
    't/phrasebook/cisco/pixos/pixos7/blah/pb',
    't/phrasebook/testing/phrases',
    't/release-20_connect.t',
    't/release-30_phrasebook.t',
    't/release-31_actionset.t',
    't/release-32_action.t',
    't/release-40_transport.t',
    't/release-41-transport_middle_of_line_prompt_match.t',
    't/release-50_cmd.t',
    't/release-60_prompt.t',
    't/release-cpan-changes.t',
    't/release-dist-manifest.t',
    't/release-kwalitee.t',
    't/release-meta-json.t',
    't/release-unused-vars.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
