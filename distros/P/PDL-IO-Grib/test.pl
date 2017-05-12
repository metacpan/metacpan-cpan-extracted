#use blib;
use PDL;
my @bpv=(4..16);
sub ok {
	my $no = shift ;
	my $result = shift ;
	print "not " unless $result ;
	print "ok $no\n" ;
}

BEGIN {
  print "1..68\n";
  ok('1 load module',eval 'use PDL::IO::Grib' eq '');
}
use Carp; 
$SIG{__DIE__} = sub {print Carp::longmess(@_); die;};

#$PDL::IO::Grib::debug=1;
#
# Create 3 random 2d piddles write them to a grib file then
# read them back and make sure they match - they won't match exactly because
# it's a lossy format.  These are more or less the minimal header fields for a 
# grib record.
#
my @a;
my $x=4;
my $y=5;
my $fname = 'tmp.grib';
unlink $fname;
my $gh = new PDL::IO::Grib($fname,'w');
my $data = float(100+random($x,$y));

for(0..$#bpv){
  $a[$_] = new PDL::IO::Grib::Field();


  $a[$_]->pds_attribute(4,2);

  $a[$_]->pds_attribute(9,1);
  $a[$_]->pds_attribute(10,109);
  $a[$_]->pds_attribute(11,$_);
  
  $a[$_]->gds_attribute(6,0);
  $a[$_]->gds_attribute(7,$x);
  $a[$_]->gds_attribute(9,$y);
  $a[$_]->bds_attribute(11,$bpv[$_]);
  $a[$_]->{DATA} = $data;


  $a[$_]->write($gh->filehandle);
    
}

$gh->close();


ok('2 create file',(-e $fname));

my $gh2 = new PDL::IO::Grib($fname);

ok('3 read fields',$gh2->fieldcnt==$#bpv+1);

#
# gets fields in the reverse order that I wrote them
#

my @b = reverse(@{$gh2->getallfields});

for(0..$#bpv){  

  my($mean1,$rms1,$median1,$min1,$max1) = ($b[$_]-$a[$_]->{DATA})->stats;
  my($mean2,$rms2,$median2,$min2,$max2) = (0,0,0,0,0) ; #$b[$_]->stats;

#  print join(' ',$b[$_]->stats),"\n";
  print "Tests for ",$a[$_]->bds_attribute(11)," bits per value packing\n";
  ok(4+5*$_ ." mean value ",approx($mean1,$mean2,0.06*2**(-$_)));
  ok(5+5*$_ ." rms",approx($rms1,$rms2,0.06/($_+1)));
  ok(6+5*$_ ." median",approx($median1,$median2,0.06/($_+1)));
  ok(7+5*$_ ." minimum",approx($min1,$min2,0.06/($_+1)));
  ok(8+5*$_ ." maximum",approx($max1,$max2,0.06/($_+1)));
}
sub approx {
	my($a,$b,$d) = @_;
	my $c = abs($a-$b);
#	$d = max($c);
#	$d < 0.01;
	print "error=$c " if($c>$d);
	$c < $d;
	
}
