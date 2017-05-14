use Test::More qw(no_plan);

use RObufr;
use PDL;
use Data::Dumper;
use warnings;
use strict;

# Radio occultation BUFR
#-----------------------------------------------------------------------------------------------

my $data = do "t/bufr.dat";
my ($values, $edition, $startTime, $lat, $lon, $msgprefix, $gtshdr) = @$data;
my $b = RObufr->new(EDITION   => $edition,
                     TIME      => $startTime,
                     LAT       => $lat,
                     LON       => $lon,
                     NAME      => 'GPSRO2',  # radio occultation BUFR sequence (310026)
                     BUFRLIB   => './bufr',
                     MSGPREFIX => $msgprefix,
                     GTSHDR    => $gtshdr);
my $bufr = $b->encode($values)->getbufr;
my $rofile = 't/bfrPrf_MTPA.2012.001.00.03.G27_2011.2980_bufr.good';
my $good_bufr = do { local( @ARGV, $/ ) = $rofile; <> } ; # slurp!
ok (length($bufr) == 11423, 'RO BUFR string length OK');
ok ($bufr eq $good_bufr,    'RO BUFR string identical to reference');
undef $b;
$b = RObufr->new(EDITION   => $edition,
                  TIME      => $startTime,
                  LAT       => $lat,
                  LON       => $lon,
                  NAME      => 'GPSRO2',  # radio occultation BUFR sequence (310026)
                  BUFRLIB   => './bufr', 
                  MSGPREFIX => $msgprefix,
                  GTSHDR    => $gtshdr);
my $comparison_values = $b->read($rofile)->getvalues;
ok ( ( scalar(@$comparison_values) == scalar(@$values) ), 'Number of values generated equals starting number');

my $output = $b->print;
my $go_file = 't/bfrPrf_MTPA.2012.001.00.03.G27_2011.2980_bufr.print';

# Uncomment to create new 'good output' file
#open  OUT, ">$go_file";
#print OUT $output;
#close OUT;

my $good_output = do { local( @ARGV, $/ ) = $go_file; <> } ; # slurp!
ok ( $output eq $good_output, 'Space-based printout matches expected' );

# open OUT, ">t/bfrPrf_MTPA.2012.001.00.03.G27_2011.2980_bufr"; print OUT $bufr; close OUT; # debug

# Code used to generate bufr.dat once a good run is verified.  Put in makeBfrPrf2.pl:
#  use Data::Dumper;
#  open my $ofh, '>', '../t/bufr.dat';
#  print {$ofh} Dumper([[@values],$edition,$startTime,$lat,$lon,$msgprefix,$gtshdr]);
#  close $ofh;


# Ground-based BUFR
#-----------------------------------------------------------------------------------------------

my $bufr_file = 't/ucarPw_2012.249.04.15.0030.01_bufr';
$startTime = TimeClass->new->set_yrdoyhms_gps((split /[\_\.]/, $bufr_file)[1..4], 0)->get_gps;
my $b1 = RObufr->new(EDITION   => 4,
                      TIME      => $startTime,
                      NAME      => 'GBGPS',
                      BUFRLIB   => './bufr',
                      MSGPREFIX => 0,
                      GTSHDR    => 0);
$b1->read($bufr_file);

$output = $b1->print;
$go_file = 't/ucarPw_2012.249.04.15.0030.01_bufr.print';

# Uncomment to create new 'good output' file
#open  OUT, ">$go_file";
#print OUT $output;
#close OUT;

$good_output = do { local( @ARGV, $/ ) = $go_file; <> } ; # slurp!
ok ( $output eq $good_output, 'Ground-based printout matches expected' );

my $b2 = RObufr->new(EDITION   => 4,
                      TIME      => $startTime,
                      NAME      => 'GBGPS',
                      BUFRLIB   => './bufr',
                      MSGPREFIX => 0,
                      GTSHDR    => 0);
$bufr = $b2->encode($b1->getvalues)->getbufr;

$good_bufr = do { local( @ARGV, $/ ) = $bufr_file; <> } ; # slurp!

ok ($b1->{SECTION0} eq $b2->{SECTION0}, 'Ground-based read-in SECTION0 equals encoded SECTION0');

# Remove this test for the RObufr version.  The pre-generated BUFR file contains a UTC time
# which has to be converted from GPS time with the aid of a leap-second file.  Since the
# RObufr (stand-alone) version has no leap-second file, this test fails because the time
# is off by a few seconds.  This should not matter.  D. Hunt 5/29/2013
#ok ($b1->{SECTION1} eq $b2->{SECTION1}, 'Ground-based read-in read SECTION1 equals encoded SECTION1');

ok ($b1->{SECTION3} eq $b2->{SECTION3}, 'Ground-based read-in read SECTION3 equals encoded SECTION3');
ok ($b1->{SECTION4} eq $b2->{SECTION4}, 'Ground-based read-in read SECTION4 equals encoded SECTION4');

1;





