#!/opt/perl5/bin/perl -w
#---------------------------------------------------------------------------
#  Copyright (c) 1999 Hewlett-Packard Company. All rights reserved.
#  This program is free software; you can redistribute it
#  and/or modify it under the same terms as Perl itself.
#
#  $Author: bbacker $
#  $Date: 2001/09/19 18:43:24 $
#  $Revision: 1.2 $
#
# interleaved starts and stops
#---------------------------------------------------------------------------

    use strict;

    use Perf::ARM;
    use Test;
    BEGIN {plan test=>1}


my ($limit, $i, $app_id, $th1, $th2, $ti1, $ti2, $rc);

($limit= shift) or ($limit=10);
$i=0;

# ai = appl id
# ti = transaction id
# th = transaction handle

################
    $app_id=Perf::ARM::arm_init( "$0", "*", 0,0,0);
    if ($app_id <=0) {
    ok(0);
	die "arm_init() failed [$app_id]: do you have a real " .
	    "libarm installed, or just a NOP version? \n";
    }

    ($ti1=Perf::ARM::arm_getid($app_id, "simple_tran1",
	"detail1_$$", 0,0,0) > 0) || die "arm_getid() failed with $ti1";

    ($ti2=Perf::ARM::arm_getid($app_id, "simple_tran2",
	"detail2_$$", 0,0,0) > 0) || die "arm_getid() failed with $ti2";

    for ($i=0;$i<$limit;$i++) {
	$th1=Perf::ARM::arm_start($ti1, 0,0,0);
	printf "%3.3d: ",$i;
	print "arm_start() trans 1 app_id: $app_id th: $th1 \n";

	$th2=Perf::ARM::arm_start($ti2, 0,0,0);
	printf "%3.3d: ",$i;
	print "arm_start() trans 2 app_id: $app_id th: $th2 \n";

	ok(0) if ( (! $th1) || (! $th2));

	sleep 1;

	$rc=Perf::ARM::arm_stop($th1, 0, 0,0,0);
	printf "%3.3d: ",$i;
	print "arm_stop()  trans 1 app_id: $app_id th: $th1 rc=$rc\n";

	ok(0) if ($rc);

	sleep 1;

	$rc=Perf::ARM::arm_stop($th2, 0, 0,0,0);
	printf "%3.3d: ",$i;
	print "arm_stop()  trans 2 app_id: $app_id th: $th2 rc=$rc\n";

	ok(0) if ($rc);
    }

    $rc=Perf::ARM::arm_end($app_id, 0,0,0);
    ok(0) if ($rc);

ok(1);
