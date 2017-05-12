#!/usr/bin/perl -w

=head1 NAME

example-getsatellitelist.pl - Net::GPSD getsatellitelist method example

=cut


use strict;
use lib qw{./lib ../lib};
use Net::GPSD;

my ($host,$port)=split(q{:}, shift()||'');
$host||=q{localhost};
$port||=q{2947};

my $gps=Net::GPSD->new(host=>$host, port=>$port) || die("Error: Cannot connect to the gpsd server");

my $i=0;
print join("\t", qw{Count PRN ELEV Azim SNR USED}), "\n";
foreach ($gps->getsatellitelist) {
  print join "\t", ++$i,
                   $_->prn,
                   $_->elev,
                   $_->azim,
                   $_->snr,
                   $_->used;
  print "\n";
}

__END__

=head1 SAMPLE OUTPUT

  Count   PRN     ELEV    Azim    SNR     USED
  1       26      12      132     38      1
  2       29      20      120     38      1
  3       7       74      231     42      1
  4       18      8       207     27      0
  5       16      23      315     36      1
  6       24      47      78      37      1
  7       2       12      81      39      1
  8       30      15      201     34      1
  9       6       74      195     40      1
  10      21      41      259     40      1
  11      10      50      64      38      1
  12      135     26      202     34      0

=cut
