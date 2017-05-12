#!perl

use 5.010;
use strict;
use warnings;

use FindBin '$Bin';
use lib $Bin, "$Bin/t";

use Org::To::HTML;
use Org::Parser;
use Test::More 0.96;
require "testlib.pl";

my $orgp = Org::Parser->new;
my $doc = $orgp->parse(<<'_');
#+TODO: A | B
* heading 1
_

# test OO interface
my $oeh = Org::To::HTML->new(naked=>1);
is($oeh->export($doc), "<H1>heading 1</H1>\n\n", "export method");

# test subclass
package MyHTMLExporter;
use Moo;
extends 'Org::To::HTML';
sub export_setting {
    my ($self, $elem) = @_;
    "<!-- setting:".$elem->name." -->\n";
}
package main;
$oeh = MyHTMLExporter->new(naked=>1);
is($oeh->export($doc),
   "<!-- setting:TODO -->\n<H1>heading 1</H1>\n\n", "export method (subclass)");

done_testing();
