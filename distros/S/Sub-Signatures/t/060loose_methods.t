#!/usr/bin/perl
# '$Id: 40loose_methods.t,v 1.1 2004/12/05 03:02:01 ovid Exp $';
use warnings;
use strict;
use Test::More tests => 6;

BEGIN
{
    chdir 't' if -d 't';
    unshift @INC => '../lib';
}
use Sub::Signatures qw/methods/;

sub foo($class, $bar) {
    $bar;
}

ok defined &__foo_2, 
    'We can have subs with one argument';
is_deeply __PACKAGE__->__foo_2({this => 'one'}), {this => 'one'},    
    '... and it should behave as expected';

is_deeply __PACKAGE__->foo({this => 'one'}), {this => 'one'},    
    '... even if we call it by its original name';

sub foo($class, $bar, $baz) {
    return [$bar, $baz];
}

ok defined &__foo_3,
    '... and we can recreate the sub with a different signature';
is_deeply __PACKAGE__->__foo_3(1,2), [1,2],
    '... and call the correct sub based upon the number of arguments';
is_deeply __PACKAGE__->foo(1,2), [1,2],
    '... even if we call it by its original name';
