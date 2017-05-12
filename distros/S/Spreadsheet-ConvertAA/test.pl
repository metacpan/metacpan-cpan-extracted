# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test;
BEGIN { plan tests => 3 };
use Spreadsheet::ConvertAA;

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

die "Can't convert 0 to baseAA\n" unless '@' eq ToAA(0) ;
ok(1);

die "Can't convert '@' from baseAA\n" unless 0 == FromAA('@') ;
ok(2);

print "This can take few minutes! (1 mn on my linux PIII/700Mhz).\n" ;
my ($p4, $p3, $p2, $p1) = ('@', '@', '@', 'A') ;

use Time::HiRes qw(gettimeofday tv_interval) ;
my $t0 = [gettimeofday];

for my $base10 (1 .. 475_254) 
	{
	my $baseAA = "$p4$p3$p2$p1" ;
	$baseAA =~ s/@//g ;
	
	my $conv = ToAA($base10) ;
	my $reconv = FromAA($conv) ;
	
	#~ print "[$base10, $baseAA] => [$conv, $reconv]\n" ;
	
	if($baseAA ne $conv || $reconv != $base10)
		{
		die "Error: [$base10, $baseAA] => [$conv, $reconv]\n" ;
		}
		
	$p1 = chr(ord($p1) + 1) ;
	
	if($p1 eq '[')
		{
		$p1 = 'A' ;
		
		$p2 = chr(ord($p2) + 1) ;
		
		if($p2 eq '[')
			{
			$p2 = 'A' ;
			$p3 = chr(ord($p3) + 1) ;
			
			if($p3 eq '[')
				{
				$p3 = 'A' ;
				$p4 = chr(ord($p4) + 1) ;
				}
			}
			
		}
	}

my $build_time = tv_interval ($t0, [gettimeofday]) ;
print(sprintf("Test time: %0.2f s.\n", $build_time)) ;
	
ok(3);
