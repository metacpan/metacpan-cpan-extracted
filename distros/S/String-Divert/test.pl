##
##  String::Divert - String Object supporting Folding and Diversion
##  Copyright (c) 2003-2005 Ralf S. Engelschall <rse@engelschall.com>
##
##  This file is part of String::Divert, a Perl module providing
##  a string object supporting folding and diversion.
##
##  This program is free software; you can redistribute it and/or
##  modify it under the terms of the GNU General Public  License
##  as published by the Free Software Foundation; either version
##  2.0 of the License, or (at your option) any later version.
##
##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
##  General Public License for more details.
##
##  You should have received a copy of the GNU General Public License
##  along with this file; if not, write to the Free Software Foundation,
##  Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA.
##
##  test.pl: Module Test Suite
##

use 5.006;
use Test::More tests => 37;

#   test: module loading
BEGIN { use_ok('String::Divert') };

#   test: object creation
my $x = new String::Divert;
ok(defined($x), "object creation");
$x->destroy;
$x = new String::Divert;
ok(defined($x), "object (re)creation");
$x->name("xx");
ok($x->name() eq "xx", "overwritten object name");
$x->name("x");
my $y = $x->clone();
ok($x != $y, "cloning");

#   test: simple content
ok($x->string() eq "", "empty initial content");
$x->append("foo");
$x->append("bar");
ok($x->string() eq "foobar", "appended content");
$x->assign("quux");
ok($x->string() eq "quux", "assigned content");
$x->assign("foo");
ok($x->string() eq "foo", "(re)assigned content");
$x->append("bar");
ok($x->string() eq "foobar", "append after assign");

#   test: content overwrite mode
$x->assign("foo");
$x->overwrite('once');
$x->append("bar");
$x->append("quux");
ok($x->string() eq "barquux", "appending with overwrite 'once'");
$x->overwrite('always');
$x->append("bar");
$x->append("quux");
ok($x->string() eq "quux", "appending with overwrite 'always'");
$x->overwrite('none');
$x->append("bar");
$x->append("quux");
ok($x->string() eq "quuxbarquux", "appending with overwrite 'none'");

#   test: content folding
$x->assign("foo");
$x->fold("bar");
$x->append("quux");
my $bar = $x->folding("bar");
ok(defined($bar), "folding object retrival 1");
ok($x->string() eq "fooquux", "folding 1");
$bar->append("bar");
ok($x->string() eq "foobarquux", "folding 2");
$bar->fold("baz");
$bar->append("bar2");
$bar->fold("baz");
$bar->append("bar3");
ok($x->string() eq "foobarbar2bar3quux", "folding 3");
my $baz = $x->folding("baz");
ok(defined($baz), "folding object retrival 2");
$baz->append("baz");
ok($baz->string() eq "baz", "folding 3");
ok($bar->string() eq "barbazbar2bazbar3", "folding 4");
ok($x->string() eq "foobarbazbar2bazbar3quux", "folding 5");
$baz->assign("XX");
ok($baz->string() eq "XX", "folding 6");
ok($bar->string() eq "barXXbar2XXbar3", "folding 7");
ok($x->string() eq "foobarXXbar2XXbar3quux", "folding 8");
my @foldings = $x->folding();
ok(@foldings == 3, "folding 9");

#   test: content diversion
$x->assign("foo");
$x->fold("bar");
$x->append("quux");
$x->divert("bar");
$x->append("bar1");
$x->fold("baz");
$x->append("bar2");
$x->divert("baz");
$x->append("baz");
ok($x->string() eq "baz", "diversion 1");
$x->undivert;
ok($x->string() eq "bar1bazbar2", "diversion 2");
$x->undivert;
ok($x->string() eq "foobar1bazbar2quux", "diversion 3");
$x->divert("bar");
$x->divert("baz");
my @diversions = $x->diversion();
ok(@diversions == 2, "diversion 4");
$x->undivert(0);
@diversions = $x->diversion();
ok(@diversions == 0, "diversion 5");

#   test: operator overloading
ok($x->overload == 0, "default overloading mode");
$x->overload(1);
ok($x->overload == 1, "default overloading mode");
$x->assign("foo");
ok("$x" eq "foo", "stringify operation");
$x .= "bar";
ok("$x" eq "foobar", "appending string");
$x *= "baz";
$x .= "quux";
ok("$x" eq "foobarquux", "appending folding");
$x >> "baz";
$x .= "baz";
$x << 0;
ok("$x" eq "foobarbazquux", "diversion");

#   configuring folder patters
$x->assign("x");
$x->folder('{#%s#}', '\{#([a-zA-Z_][a-zA-Z0-9_.-]*)#\}');
ok("$x" eq "x", "folder pattern 1");

