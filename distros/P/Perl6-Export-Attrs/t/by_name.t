use Test::More tests => 1;

package Lib;
use Perl6::Export::Attrs;
sub doit :Export { "Do it!"; }
1;

package main;
import Lib qw(doit);

is(doit(), "Do it!", "function exported as expected");

