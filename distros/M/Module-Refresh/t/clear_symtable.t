#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Module::Refresh;

use File::Temp;
use Path::Class;

my $dir = File::Temp->newdir;
push @INC, $dir->dirname;

dir($dir)->file('Foo.pm')->openw->print(<<'PM');
package Foo;
sub bar { }
1;
PM

require Foo;

Module::Refresh->refresh;

can_ok('Foo', 'bar');
ok(!Foo->can('baz'), "!Foo->can('baz')");

sleep 2;

dir($dir)->file('Foo.pm')->openw->print(<<'PM');
package Foo;
sub baz { }
1;
PM

Module::Refresh->refresh;

can_ok('Foo', 'baz');
ok(!Foo->can('bar'), "!Foo->can('bar')");

done_testing;
__END__
ok 1 - Foo->can('bar')
ok 2 - !Foo->can('baz')
ok 3 - Foo->can('baz')
not ok 4 - !Foo->can('bar')
#   Failed test '!Foo->can('bar')'
#   at test.pl line 38.
1..4
# Looks like you failed 1 test of 4.
