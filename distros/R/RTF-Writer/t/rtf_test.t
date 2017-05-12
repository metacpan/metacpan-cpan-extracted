
require 5.005; # we need m/...\z/
# Time-stamp: "2003-10-14 17:56:45 ADT"

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use Test;

BEGIN { plan tests => 11 }
END {print "not ok 1\n" unless $loaded;}
use RTF::Writer ('rtfesc');

sub isbal ($) { (my $x = $_[0]) =~ tr/\{\}//cd; while($x =~ s/\{\}//g){;}; length($x) ? 0 : 1 }

$loaded = 1;
ok 1;

print "# RTF::Writer version: $RTF::Writer::VERSION\n",
      "# Perl version: $] on OS \"$^O\"\n";

# First let's make sure out isbal works
ok isbal('{aoeaoe}aoe');
ok isbal('aoeaoe');
ok isbal('a{o{e}aoe}');
ok isbal('a{o{e{}a}{oe}}');
ok isbal('a{o{e}aoe}');
ok!isbal('a}oe{aoe');
ok!isbal('a}oe{ao}e');



# Pretty elementary test.

my $x = rtfesc("foo{\\\n");
ok $x, "foo\\'7b\\'5c\n\\line ";

$x = '';
my $r = RTF::Writer->new_to_string(\$x);
$r->print("foo{\\\n");
$r->close;
ok $x, "foo\\'7b\\'5c\n\\line ";
ok isbal($x), 1, "Unbalanced: $x";

###########################################################################
$| = 1;

