use strict;
use warnings;
use Test::More tests => 1;
use String::Template;

my %fields = ( num => 2, str => 'this', date => 'Feb 27, 2008' );

my $template = "...<num%04d>...<str>...<date:%Y/%m/%d>...\n";

my $correct = "...0002...this...2008/02/27...\n";

my $exp = expand_string($template, \%fields);

is($exp, $correct, "test expand");


