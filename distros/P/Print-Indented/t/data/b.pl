package
    t::data::b;
use strict;
use warnings;
use Print::Indented;

for (qw(xxx yyy)) {
    print "---\n$_\n";
}

do 't/data/a.pl';
