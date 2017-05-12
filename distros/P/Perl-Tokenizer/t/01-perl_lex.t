#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 10;

BEGIN {
    use_ok('Perl::Tokenizer') || print "Bail out!\n";

    my @expected = qw(
      keyword
      horizontal_space
      scalar_sigil
      var_name
      horizontal_space
      operator
      horizontal_space
      number
      semicolon
      );

    Perl::Tokenizer::perl_tokens(
        sub {
            my ($token) = @_;
            is($token, shift(@expected));
        },
        'my $num = 42;'
                                );
}
