use strict;
use warnings;

BEGIN { $^P |= 0x210 }

use Test::More 0.88;
use Sub::Name;

my $x = subname foo => sub { (caller 0)[3] };
my $line = __LINE__ - 1;
my $file = __FILE__;
my $anon = $DB::sub{"main::__ANON__[${file}:${line}]"};

is($x->(), "main::foo");

package Blork;

use Sub::Name;

subname " Bar!", $x;
::is($x->(), "Blork:: Bar!");

subname "Foo::Bar::Baz", $x;
::is($x->(), "Foo::Bar::Baz");

subname "subname (dynamic $_)", \&subname  for 1 .. 3;

for (4 .. 5) {
    subname "Dynamic $_", $x;
    ::is($x->(), "Blork::Dynamic $_");
}

::is($DB::sub{"main::foo"}, $anon);

for (4 .. 5) {
    ::is($DB::sub{"Blork::Dynamic $_"}, $anon);
}

for ("Blork:: Bar!", "Foo::Bar::Baz") {
    ::is($DB::sub{$_}, $anon);
}

::done_testing;
# vim: ft=perl
