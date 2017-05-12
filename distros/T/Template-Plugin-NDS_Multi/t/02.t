#!/usr/bin/perl -w

require 5.001;

$runtests=shift(@ARGV);
if ( -f "t/test.pl" ) {
  require "t/test.pl";
  $dir="t";
} elsif ( -f "test.pl" ) {
  require "test.pl";
  $dir=".";
} else {
  die "ERROR: cannot find test.pl\n";
}

unshift(@INC,$dir);
use Template;
use Template::Constants qw( :debug );
use IO::File;

use Data::NDS::Multifile;

$obj = new Data::NDS::Multifile;
$obj->file("1","$dir/02_1.yaml");
$obj->file("2","$dir/02_2.yaml");
$obj->default_element("_default_1");
$obj->default_element("_default_2");

test($obj,"02",$runtests);

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 3
# cperl-continued-statement-offset: 2
# cperl-continued-brace-offset: 0
# cperl-brace-offset: 0
# cperl-brace-imaginary-offset: 0
# cperl-label-offset: -2
# End:

