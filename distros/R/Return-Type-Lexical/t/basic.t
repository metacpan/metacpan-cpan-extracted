#!/usr/bin/env perl

use warnings;
use strict;

use Test::Exception;
use Test::More;

use Types::Standard qw(Int);

{
    use Return::Type::Lexical;
    sub foo :ReturnType(Int) { 'not an int' }
    no Return::Type::Lexical;
    sub bar :ReturnType(Int) { 'not an int' }
    use Return::Type::Lexical check => 0;
    sub baz :ReturnType(Int) { 'not an int' }
}

dies_ok   { my $dummy = foo() } 'return type enforced';
lives_and { my $dummy = bar(); is $dummy, 'not an int' } 'return type not enforced';
lives_and { my $dummy = baz(); is $dummy, 'not an int' } 'return type not enforced';
dies_ok   { my $dummy = Other::qux() } 'return type enforced when using Return::Type directly';

done_testing;

{
    package Other;

    use Types::Standard qw(Int);
    use Return::Type;

    sub qux :ReturnType(Int) { 'not an int' }
}
