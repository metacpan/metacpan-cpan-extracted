#!/usr/bin/perl

use strict;
use Test;

BEGIN{
   plan tests => 12;
}

our $C;
use Sub::Caller;

ok(test('a'), '');
ok($C, undef);
&Sub::Caller::addCaller('test');
ok(test('b'), 1);
ok($C->{file}, 't/caller.t');
ok($C->{line}, 16);
ok($C->{package}, 'main');
ok($C->{function}, 'main');
iTest();



sub iTest {
   ok(test('1'), 1);
   ok($C->{file}, 't/caller.t');
   ok($C->{line}, 26);
   ok($C->{package}, 'main');
   ok($C->{function}, 'iTest');
}

sub test {
   my ($a, $caller) = @_;
   $C = $caller;
   Sub::Caller::isCaller($caller);
}

1;
__END__

