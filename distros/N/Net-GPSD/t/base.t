# -*- perl -*-

use constant NEAR_DEFAULT => 7;

sub near {
  my $x=shift();
  my $y=shift();
  my $p=shift()||NEAR_DEFAULT;
  if (($x-$y)/$y < 10**-$p) {
    return 1;
  } else {
    return 0;
  }
}

BEGIN {
    if (!eval q{
	use Test;
	1;
    }) {
	print "1..0 # tests only works with installed Test module\n";
	exit;
    }
}

BEGIN { plan tests => 53 }

# just check that all modules can be compiled
ok(eval {require Net::GPSD; 1}, 1, $@);
ok(eval {require Net::GPSD::Point; 1}, 1, $@);
ok(eval {require Net::GPSD::Satellite; 1}, 1, $@);
ok(eval {require Net::GPSD::Report::http; 1}, 1, $@);

my $g = Net::GPSD->new(do_not_init=>1);
ok(ref $g, "Net::GPSD");
ok($g->host, "localhost");
$g->host('127.0.0.1');
ok($g->host, "127.0.0.1");
ok($g->port, "2947");
$g->port(2948);
ok($g->port, "2948");
$g->port(2947);
ok($g->port, "2947");

my $p = Net::GPSD::Point->new();
ok(ref $p, "Net::GPSD::Point");

my $s = Net::GPSD::Satellite->new();
ok(ref $s, "Net::GPSD::Satellite");

my $gpsprn=GPS::OID->new();
my $oid21=$gpsprn->oid_prn(21); #oid not static cannot hard code
my $oid23=$gpsprn->oid_prn(23); #oid not static cannot hard code

my $s1=Net::GPSD::Satellite->new(qw{23 37 312 34 0});
ok($s1->prn, 23);
ok($s1->elevation, 37);
ok($s1->azimuth, 312);
ok($s1->snr, 34);
ok($s1->used, 0);
ok($s1->oid, $oid23);

$s1=Net::GPSD::Satellite->new();
$s1->prn(23);
ok($s1->prn, 23);
ok($s1->oid, $oid23);
$s1->oid($oid21);
ok($s1->prn, 21);
ok($s1->oid, $oid21);

my $p1 = Net::GPSD::Point->new({
           O=>[qw{tag 1142128600 o2 38.865343 -77.110069 o5 o6 o7
                  53.649377382 21.37913373 o10 o11 o12 o13}],
           D=>['2006-03-04T05:52:03.77Z'],
           M=>[3],
           S=>[1]
         });
my $p2 = Net::GPSD::Point->new({
           O=>[qw{. 1142128605 . 38.866119 -77.109338 . . . . . . . . .}],
         });
ok($p1->fix, 1);
ok($p1->status, 1);
ok($p1->datetime, '2006-03-04T05:52:03.77Z');
ok($p1->tag, 'tag');
ok($p1->time, 1142128600);
ok($p1->errortime, 'o2');
ok($p1->latitude, 38.865343);
ok($p1->lat, 38.865343);
ok($p1->longitude, -77.110069);
ok($p1->lon, -77.110069);
ok($p1->latlon."", "38.865343 -77.110069");
ok(($p1->latlon)[0], 38.865343);
ok(($p1->latlon)[1], -77.110069);
ok($p1->altitude, 'o5');
ok($p1->alt, 'o5');
ok($p1->errorhorizontal, 'o6');
ok($p1->errorvertical, 'o7');
ok(near $p1->heading, 53.649377382);
ok(near $p1->speed, 21.37913373);
ok($p1->climb, 'o10');
ok($p1->errorheading, 'o11');
ok($p1->errorspeed, 'o12');
ok($p1->errorclimb, 'o13');
ok($p1->mode, 3);

ok($g->time($p1,$p2), 5);
ok near($g->distance($p1,$p2), 106.9869, 5); #from fortran
my $p3=$g->track($p1, 5);
ok near($p3->lat, 38.8659140849351);
ok near($p3->lon, -77.1090757100891);
ok($p3->time, 1142128605);
ok($g->distance($p1,$p1) < 1e-7); #should be very close to zero
ok($g->time($p2,$p3), 0);
