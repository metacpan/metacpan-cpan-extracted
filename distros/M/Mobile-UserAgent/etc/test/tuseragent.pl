#!/usr/bin/perl -w
use strict;
use FindBin;
use lib ("$FindBin::Bin/../../lib");
use Mobile::UserAgent;

my @lines = <DATA>;
foreach my $line (@lines) {
 chomp($line);
 my $o = Mobile::UserAgent->new($line);
 print "$line ...";
 print defined($o->vendor()) && defined($o->model()) ? 'OK' : 'FAIL';
 print "\n";
 if (defined($o->vendor()) && defined($o->model())) {
  print $o->vendor() . ' ' . $o->model() . "\n";
 }
}

__DATA__
portalmmm/2.0 S341i(c10;TB)
portalmmm/1.0 m21i-10(c10)
portalmmm/2.0 TS21i-10(c10)
portalmmm/2.0 N401i (c20;TB)
portalmmm/1.0 n22i-10(c10)
portalmmm/1.0 n21i-xx(c10)
portalmmm/2.0 SG341i(c10;TB)
portalmmm/2.0 L341i(c10;TB)
portalmmm/2.0 SI400i(c10;TB)