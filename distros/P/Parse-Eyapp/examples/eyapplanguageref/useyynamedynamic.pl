#!/usr/bin/perl -w
use YYNameDynamic;
use Data::Dumper;

$parser = YYNameDynamic->new();
my $tree = $parser->Run;
$Data::Dumper::Indent = 1;
if (defined($tree)) { print Dumper($tree); }
else { print "Error: invalid input\n"; }
