#!/usr/bin/perl -w

=head1 NAME

example-check.pl - Reads the "O" array and the corresponding methods

=cut

use strict;
use lib qw{./lib ../lib};
use Net::GPSD;

my ($host,$port)=split(q{:}, shift()||'');
$host||=q{localhost};
$port||=q{2947};

my $gps=Net::GPSD->new(host=>$host, port=>$port) || die("Error: Cannot connect to the gpsd server");

while (1) {
  my $p=$gps->get();
  if ($p->fix) {
    print "--", join("|", map {defined $_?$_:''}
                     $p->tag,
                     $p->time,
                     $p->errortime,
                     $p->lat,
                     $p->lon,
                     $p->alt,
                     $p->errorhorizontal,
                     $p->errorvertical,
                     $p->heading,
                     $p->speed,
                     $p->climb,
                     $p->errorheading,
                     $p->errorspeed,
                     $p->errorclimb,
                     $p->mode),
                     "\n";
    print "O=", join("|", map {defined $_?$_:''} @{$p->{'O'}}),"\n";
  }
  sleep 1;
}

__END__

=head1 SAMPLE OUTPUT

  --MID28|1168722239.380|0.005|53.527136|-113.530150|704.57|1.60|1.28|0.0000|0.000|0.000||0.00||3
  O=MID28|1168722239.380|0.005|53.527136|-113.530150|704.57|1.60|1.28|0.0000|0.000|0.000||0.00||3
  --MID28|1168726527.070|0.005|53.527163|-113.530174|702.39|1.60|1.44|109.6857|0.053|0.169|50.9684|0.00||3
  O=MID28|1168726527.070|0.005|53.527163|-113.530174|702.39|1.60|1.44|109.6857|0.053|0.169|50.9684|0.00||3
  --MID29|1168726527.070|0.005|53.527163|-113.530174|702.39|1.60|1.44|109.6857|0.053|0.169|50.9684|0.00||3
  O=MID29|1168726527.070|0.005|53.527163|-113.530174|702.39|1.60|1.44|109.6857|0.053|0.169|50.9684|0.00||3

=cut
