#!/usr/bin/perl -w

use strict;

use Test::More qw/no_plan/;
use File::Temp 'tempdir';
my $tmp = tempdir( CLEANUP => 1 );

my $file = $tmp."/".'FooBar.pm';
push @INC, $tmp;

write_out(<<".");
package Foo::Bar;
sub foo { 'bar' }
1;
.

use_ok('Module::Refresh');

use_ok('FooBar', "Required our dummy module");

my $r = Module::Refresh->new();

# is our non-file-based method available?

can_ok('Foo::Bar', 'not_in_foobarpm');

is(Foo::Bar->foo, 'bar', "We got the right result");

write_out(<<".");
package Foo::Bar; 
sub foo { 'baz' }
1;
.

is(Foo::Bar->foo, 'bar', "We got the right result, still");

$r->refresh;

is(Foo::Bar->foo, 'baz', "We got the right new result,");

# After a refresh, did we blow away our non-file-based comp?
can_ok('Foo::Bar', 'not_in_foobarpm');

$r->unload_subs($file);
ok(!defined(&Foo::Bar::foo), "We cleaned out the 'foo' method'");

#ok(!UNIVERSAL::can('Foo::Bar', 'foo'), "We cleaned out the 'foo' method'");
#require "FooBar.pm";
#is(Foo::Bar->foo, 'baz', "We got the right new result,");

sub write_out {
    local *FH;
    open FH, "> $file" or die "Cannot open $file: $!";
    print FH $_[0];
    close FH;
}

END {
    unlink $file;
}


package Foo::Bar;

sub not_in_foobarpm {
    return "woo";
}

1;
