#!/usr/bin/perl

use Text::CSV_XS;
use Locale::Country;

$csv = new Text::CSV_XS;

while (<>) {
  my $status = $csv->parse($_) or die "can't parse: ".$csv->error_input."\n";
  my($cid, $name) = $csv->fields();

  print "  '".country2code($name). "' => ", $cid. ",\n";
}
