#!perl

use strict;
use warnings;

use Test::More tests => 19;
use Shell::Autobox qw(perl);

is('print "";'->perl, '');
is('print "0";'->perl, '0');
is('print "hello, world"'->perl(), 'hello, world');
is('print "hello, world"'->perl->perl('-pe', 'tr/a-z/A-Z/'), 'HELLO, WORLD');

is(perl('print "hello, world"'), 'hello, world');
is(perl(perl('print "hello, world"'), '-pe', 'tr/a-z/A-Z/'), 'HELLO, WORLD');

eval { '1 = 1'->perl() };
ok ($@ =~ /Can't modify constant item in scalar assignment/);

eval { perl('1 = 1') };
ok ($@ =~ /Can't modify constant item in scalar assignment/);

eval { '1 = 1'->perl->perl('-pe', 's/1/2/') };
ok ($@ =~ /Can't modify constant item in scalar assignment/);

eval { perl(perl('1 = 1'), '-pe', 's/1/2/') };
ok ($@ =~ /Can't modify constant item in scalar assignment/);

{
    local $SIG{__WARN__} = sub { ok($_[0] =~ /Use of uninitialized value in print/) };
    is('print "hello, world", undef'->perl('-w'), 'hello, world');
    is('print "hello, world", undef'->perl('-w')->perl('-pe', 'tr/a-z/A-Z/'), 'HELLO, WORLD');
    is(perl('print "hello, world", undef', '-w'), 'hello, world');
    is(perl(perl('print "hello, world", undef', '-w'), '-pe', 'tr/a-z/A-Z/'), 'HELLO, WORLD');
}

# arrayref as stdin
{
    my $lines = [ map { "$_$/" } 1 .. 10 ];
    my $want = join('', map { "$_$/" } 1, 4, 9, 16, 25, 36, 49, 64, 81, 100);
    my $got = $lines->perl('-lpe', '$_ = $_ ** 2');

    is($got, $want);
}
