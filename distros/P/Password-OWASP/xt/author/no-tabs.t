use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Password/OWASP.pm',
    'lib/Password/OWASP/AbstractBase.pm',
    'lib/Password/OWASP/Argon2.pm',
    'lib/Password/OWASP/Bcrypt.pm',
    'lib/Password/OWASP/Scrypt.pm',
    't/00-compile.t',
    't/010-bcrypt.t',
    't/020-scrypt.t',
    't/030-argon2.t'
);

notabs_ok($_) foreach @files;
done_testing;
