use strict;
use warnings;
use utf8;
use Regexp::Lexer qw(tokenize);

use Test::More;

subtest 'empty' => sub {
    my $tokens = tokenize(qr{});
    is_deeply($tokens->{tokens}, []);
};

done_testing;

