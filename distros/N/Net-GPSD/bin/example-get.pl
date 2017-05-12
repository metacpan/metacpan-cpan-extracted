#!/usr/bin/perl

=head1 NAME

example-get.pl - Net::GPSD get method example

=cut

use strict;
use warnings;
use Net::GPSD;

my ($host,$port)=split(q{:}, shift()||'');
$host||=q{localhost};
$port||=q{2947};

my $gps=Net::GPSD->new(host=>$host, port=>$port) || die("Error: Cannot connect to the gpsd server");

print join("|", qw{mode time lat lon alt speed heading}), "\n";
foreach (0..5) {
  my $p=$gps->get;
  if ($p->fix) {
    print join("|",  map {defined $_?$_:''}
                     $p->mode,
                     $p->time,
                     $p->lat,
                     $p->lon,
                     $p->alt,
                     $p->speed,
                     $p->heading),
                     "\n";
  } else {
    print "No fix\n";
  }
  sleep 1;
}

__END__

=head1 SAMPLE OUTPUT

  mode|time|lat|lon|alt|speed|heading
  3|1168726531.070|53.527167|-113.530166|700.80|0.074|0.0000
  3|1168726531.070|53.527167|-113.530166|700.80|0.074|0.0000
  3|1168726531.070|53.527167|-113.530166|700.80|0.074|0.0000
  3|1168726531.070|53.527167|-113.530166|700.80|0.074|0.0000

=cut
