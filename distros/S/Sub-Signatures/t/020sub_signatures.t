#!/usr/bin/perl
# '$Id: 10sub_signatures.t,v 1.3 2004/12/05 21:19:33 ovid Exp $';
use warnings;
use strict;

#use Test::More qw/no_plan/;
use Test::More tests => 11;

use Test::Exception;

my $CLASS;

BEGIN {

    #$ENV{SS_DEBUG} = 1;
    chdir 't' if -d 't';
    unshift @INC => '../lib';
    $CLASS = 'Sub::Signatures';
    use_ok($CLASS) or die;
}

sub foo($bar) {
    $bar;
}

ok defined &foo, 'We can have subs with one argument';
is foo(3), 3, '... and it should behave as expected';

throws_ok { foo( 1, 2 ) }
  qr/\QCould not find a sub matching your signature: foo(SCALAR, SCALAR)\E/,
  '... and it should die with an appropriate error message';

sub bar($bar, $baz) {
    [ $baz, $bar ];
}

ok defined &bar, 'We can have subs with multiple arguments';
is_deeply bar( 1, 2 ), [ 2, 1 ], '... and it should also behave as expected';

sub baz($this, $that) { [ $this, $that ] }

ok defined &baz, 'We should be able to declare subs on one line';
is_deeply baz( 1, 2 ), [ 1, 2 ], '... and they should still behave as expected';

sub first_four($string) {
    if ( substr( $string, 0, 4 ) eq 'good' ) {
        return 'ok';
    }
    else {
        return 'not ok';
    }
}
is first_four("goodness"), "ok", 'substr() should not confuse the filter';

sub _private($this, $that) {
    return "$that $this";
}

sub _private($one_argument) {
    return scalar reverse $one_argument;
}

is _private(qw/foo bar/), "bar foo",
  'We should be able to dispatch to "private" subs';

is _private('foo'), 'oof', '... based on the number of arguments';
