# -*-perl-*-
#

use Test::More tests => 28;
use Test::Exception;

use PDLA;
use PDLA::Image2D;

use strict;
use warnings;

kill 'INT',$$ if $ENV{UNDER_DEBUGGER}; # Useful for debugging.

{
	# Right answer
	my $ans = pdl(
	  [ 3,  9, 15, 21, 27, 33, 39, 45, 51, 27],
	  [ 3,  9, 15, 21, 27, 33, 39, 45, 51, 27],
	  [ 3,  9, 15, 21, 27, 33, 39, 45, 51, 27]
	);

	# conv2d
	my $pa = xvals zeroes 10,3;
	my $pb = pdl [1,2],[2,1];
	my $pc = conv2d ($pa, $pb);
	ok all approx( $pc, $ans );  # 1
}

{
	# conv2d
	my $pa = zeroes(3,3);
	$pa->set(1,1,1);
	my $pb = sequence(3,3);
	ok all approx( conv2d($pa,$pb), $pb );    # 2
}

{
	# conv2d: boundary => reflect
	my $pa = ones(3,3);
	my $pb = sequence(3,3);

	{
		my $ans = pdl ([12,18,24],[30,36,42],[48,54,60]);
		ok all approx( conv2d($pb,$pa,{Boundary => 'Reflect'}), $ans );  #3
	}

	{
		# conv2d: boundary => replicate
		my $ans = pdl ([12,18,24],[30,36,42],[48,54,60]);
		ok all approx( conv2d($pb,$pa,{Boundary => 'Replicate'}), $ans ); #4
	}

	{
		# conv2d: boundary => truncate
		my $ans = pdl ([8,15,12],[21,36,27],[20,33,24]);
		ok all approx( conv2d($pb,$pa,{Boundary => 'Truncate'}), $ans ); #5
	}
}

{
	# max2d_ind
	my $pa = 100 / (1.0 + rvals(5,5));
	$pa = $pa * ( $pa < 90 );
	my @ans = $pa->max2d_ind();
	note "max2d_ind: " . join( ',', @ans ) . "\n";
	ok( ($ans[0] == 50) & ($ans[1] == 1) & ($ans[2] == 2) );
}

{
	# centroid2d
	my $pa = 100.0 / rvals( 20, 20, { Centre => [ 8, 12.5 ] } );
	$pa = $pa * ( $pa >= 9 );
	my @ans = $pa->centroid2d( 10, 10, 20 );
	ok all approx( $ans[0], 8.432946  );  # numbers calculated by an independent program
	ok all approx( $ans[1], 11.756724 );
}

{
	# med2d
	my $pa = zeroes(5,5);
	my $t = $pa->slice("1:3,1:3");
	$t .= ones(3,3);
	my $pb = sequence(3,3);
	my $ans = pdl ( [0,0,0,0,0],[0,0,1,0,0],[0,1,4,2,0],[0,0,4,0,0],[0,0,0,0,0]);
	ok all approx( med2d($pa,$pb), $ans );
}

{
	# patch2d
	my $pa = ones(5,5);
	my $mask = zeroes(5,5);
	$mask->set(2,2,1);
	ok all approx( patch2d($pa,$mask), $pa );  # 6

	# note:
	#   with no bad values, any bad pixel which has no good neighbours
	#   has its value copied
	#
	my $m = $mask->slice('1:3,1:3');
	$m .= 1;
	my $ans = $pa->copy;
	note $pa, $mask, patch2d($pa,$mask);
	ok all approx( patch2d($pa,$mask), $ans );  # 7
}

SKIP: {
	skip "PDLA::Bad support not available.", 5 unless $PDLA::Bad::Status;

	my $pa = ones(5,5);
	# patchbad2d: bad data
	my $m = $pa->slice('1:3,1:3');
	$m .= $pa->badvalue;
	$pa->badflag(1);        # should sort out propagation of badflag

	my $ans = ones(5,5);
	$ans->set(2,2,$ans->badvalue);
	$ans->badflag(1);

	#note $pa, patchbad2d($pa);
	ok all approx( patchbad2d($pa), $ans );  # 8

	# patchbad2d: good data
	$pa = sequence(5,5);
	#note $pa, patchbad2d($pa);
	ok all approx( patchbad2d($pa), $pa );  # 9

	# max2d_ind
	$pa = 100 / (1.0 + rvals(5,5));
	$pa = $pa->setbadif( $pa > 90 );
	my @ans = $pa->max2d_ind();
	note "max2d_ind: " . join( ',', @ans );
	ok( ($ans[0] == 50) & ($ans[1] == 1) & ($ans[2] == 2) );

	# centroid2d
	$pa = 100.0 / rvals( 20, 20, { Centre => [ 8, 12.5 ] } );
	$pa = $pa->setbadif( $pa < 9 );
	@ans = $pa->centroid2d( 10, 10, 20 );
	ok all approx( $ans[0], 8.432946  );  # numbers should be same as when set < 9 to 0
	ok all approx( $ans[1], 11.756724 );
}

{
	# box2d bug test
	my $one = random(10,10);
	my $box = cat $one,$one,$one;

	my $bav = $one->box2d(3,3,0);
	my $boxav = $box->box2d(3,3,0);

	# all 2D averages should be the same
	ok all approx($bav->sum,$boxav->clump(2)->sumover);
}

{
	# cc8compt & cc4compt
	my $pa = pdl([0,1,1,0,1],[1,0,1,0,0],[0,0,0,1,0],[1,0,0,0,0],[0,1,0,1,1]);
	ok(cc8compt($pa)->max == 4);
	ok(cc4compt($pa)->max == 7);
	dies_ok { ccNcompt($pa,5); };
	lives_ok { ccNcompt($pa,8) };
	my $im = (xvals(25,25)+yvals(25,25));
	my $seg_b = cc4compt(byte $im%2);
	ok($seg_b->type >= long);
	ok(cc4compt($im%2)->max == $seg_b->max);
}

{
	# pnpoly
	my $px = pdl(0,3,1);
	my $py = pdl(0,1,4);
	my $im = zeros(5,5);
	my $im2 = zeroes(5,5);
	my $x = $im->xvals;
	my $y = $im->yvals;
	my $ps = $px->cat($py)->xchg(0,1);
	my $im_mask = pnpoly($x,$y,$px,$py);
	ok(sum($im_mask) == 5);
	my $inpixels = pdl q[ 1 1 ; 1 2 ; 1 3 ; 2 1 ; 2 2 ];
	ok(sum($inpixels - qsortvec(scalar whichND($im_mask))) == 0);

	# Make sure the PDLA pnpoly and the PP pnpoly give the same result
	ok(all($im_mask == $im->pnpoly($ps)));

	# Trivial test to make sure the polyfills using the pnpoly algorithm are working
	$im .= 0;
	polyfillv($im2,$ps,{'Method'=>'pnpoly'}) .= 22;
	ok(all(polyfill($im,$ps,22,{'Method'=>'pnpoly'}) == $im2));


	# Trivial test to make sure the polyfills are working
	$im .= 0;
	$im2 .= 0;
	polyfillv($im2,$ps) .= 25;
	polyfill($im,$ps,25);
	ok(all($im == $im2));
}
