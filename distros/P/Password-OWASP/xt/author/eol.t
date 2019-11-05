use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Password/OWASP.pm',
    'lib/Password/OWASP/AbstractBase.pm',
    'lib/Password/OWASP/AbstractBaseX.pm',
    'lib/Password/OWASP/Argon2.pm',
    'lib/Password/OWASP/Bcrypt.pm',
    'lib/Password/OWASP/Scrypt.pm',
    't/00-compile.t',
    't/010-bcrypt.t',
    't/020-scrypt.t',
    't/030-argon2.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
