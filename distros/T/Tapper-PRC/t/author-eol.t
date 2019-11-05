
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/tapper-automatic-test.pl',
    'bin/tapper-client',
    'bin/tapper-client-no-fork',
    'bin/tapper-minion-worker',
    'lib/Tapper/PRC.pm',
    'lib/Tapper/PRC/Testcontrol.pm',
    't/00-load.t',
    't/01-tapper-prc.t',
    't/02-tapper-prc-testcontrol.t',
    't/author-eol.t',
    't/author-pod-syntax.t',
    't/executables/ripley',
    't/executables/xl',
    't/executables/xm',
    't/files/append/another.stderr',
    't/files/append/another.stdout',
    't/files/append/output-001.stderr',
    't/files/append/output-001.stdout',
    't/files/append/output.stderr',
    't/files/append/output.stdout',
    't/files/args.sh',
    't/files/arguments.conf',
    't/files/exec/sleep.sh',
    't/files/multitest.conf',
    't/files/tapper.backup',
    't/files/tapper.config',
    't/files/xen/guest_1.svm',
    't/files/xen/guest_1.xl',
    't/tapper-prc-sendtap.t',
    't/tapper-prc-testcontrol-env.t',
    't/tapper-prc-testcontrol-filenames.t',
    't/tapper-prc-testcontrol-gueststart.t',
    't/tapper-prc-testcontrol-sync.t',
    't/tapper-prc-testcontrol-timeouts.t',
    't/tapper-prc-testcontrol-upload.t'
);

eol_unix_ok($_, { trailing_whitespace => 0 }) foreach @files;
done_testing;
