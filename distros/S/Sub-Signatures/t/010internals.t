#!/usr/bin/perl
# '$Id: 05internals.t,v 1.1 2004/12/05 21:19:33 ovid Exp $';
use warnings;
use strict;
use Test::More tests => 4;

# These tests are for some of the internals.  Do not depend on them.  In fact,
# you can ignore them entirely.  There are no user-serviceable parts in here
# and nothing in this tested in here is guaranteed to remain the same.

BEGIN
{
    chdir 't' if -d 't';
    unshift @INC => '../lib';
}

{
    use Sub::Signatures;

    sub foo($bar) {
        $bar;
    }
    sub foo($bar, $baz) {
        return [$bar, $baz];
    }

    ok defined &__foo_1, 
        'We can have subs with one argument';
    is_deeply __foo_1({this => 'one'}), {this => 'one'},    
        '... and it should behave as expected';
    ok defined &__foo_2,
        '... and we can recreate the sub with a different signature';
    is_deeply __foo_2(1,2), [1,2],
        '... and call the correct sub based upon the number of arguments';
}
