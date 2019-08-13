#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok('Template::Plugin::Filter::PlantUML') || print "Bail out!\n";
}

#diag(
#"Testing Template::Plugin::Filter::PlantUML $Template::Plugin::Filter::PlantUML::VERSION, Perl $], $^X"
#);
