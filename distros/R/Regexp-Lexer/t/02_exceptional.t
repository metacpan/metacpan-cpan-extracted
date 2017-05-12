use strict;
use warnings;
use utf8;
use Regexp::Lexer qw(tokenize);

use Test::More;

eval {
    tokenize('foobarbuz'); # <= not regexp quoted
};

ok $@, 'Should die when not regexp quoted argument is given';

done_testing;

