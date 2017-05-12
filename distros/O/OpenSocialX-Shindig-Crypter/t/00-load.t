#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('OpenSocialX::Shindig::Crypter');
}

diag(
"Testing OpenSocialX::Shindig::Crypter $OpenSocialX::Shindig::Crypter::VERSION, Perl $], $^X"
);
