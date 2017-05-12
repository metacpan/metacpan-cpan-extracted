#!/usr/bin/perl
# '$Id: 10sub_signatures.t,v 1.3 2004/12/05 21:19:33 ovid Exp $';
use warnings;
use strict;

#use Test::More qw/no_plan/;
use Test::More tests => 5;

use Test::Exception;

my $CLASS;

BEGIN {
    chdir 't' if -d 't';
    unshift @INC => '../lib';
}

use Sub::Signatures;

sub foo($bar) {
    return sub ($this) { "$this $bar" };
}

ok defined &foo, 'We can have subs with one argument';
my $code = foo('2');
is ref $code, 'CODE', '... and it should return the correct value';
is $code->(4), '4 2', '... and anonymous subs should be able to take arguments';

sub bar($foo) {
    return 
    sub 
    (
        $this,
$that
 )
    { 
        "$this $that $foo"
    };
}

$code = bar('2');
is ref $code, 'CODE', 'We should be able to handle very funky formatting';
is $code->(4, 5), '4 5 2', 
    '... and anonymous subs should be able to take multiple arguments';

