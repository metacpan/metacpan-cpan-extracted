use strict;
use warnings;
use Test::More;
use Test::Fatal;

use FindBin qw($Bin);
use lib "$Bin/lib";

use Local::Example;

is( Local::Example->new_foo(foo => 42)->foo, 42 );
is( Local::Example->new_bar(bar => 42)->bar, 42 );
is( Local::Example->new_baz(baz => 42)->baz, 42 );

my $foo = Local::Example->new_foo;
my $bar = Local::Example->new_bar;

is( $bar->do_it($foo), 66 );

isnt( exception{ $bar->do_it($bar) }, undef );

done_testing;

