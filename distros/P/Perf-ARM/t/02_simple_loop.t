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
# simple test script to see that starts and stops work
# make sure you've added entries to ttd.conf before trying this
#---------------------------------------------------------------------------

    use strict;
    use Perf::ARM;

    use Test;
    BEGIN {plan test=>1}

my ($i,$limit,$app_id,$tran_handle, $tran_id, $rc);

($limit= shift) or ($limit=10);
$i=0;

################

    $app_id=Perf::ARM::arm_init( "$0", "*", 0,0,0);
    if ($app_id <=0) {
    ok(0);
	die "arm_init() failed [$app_id]: do you have a real " .
	    "libarm installed, or just a NOP version? \n";
    }


    $tran_id=Perf::ARM::arm_getid($app_id, "simple_tran",
	"detail_$$", 0,0,0);
    ok(0) if (! $tran_id);


    for ($i=0;$i<$limit;$i++) {
	$tran_handle=Perf::ARM::arm_start($tran_id, 0,0,0);

	printf "%3.3d: ",$i;
	print "arm_start() transaction app_id:$app_id " .
	    "tran_handle: $tran_handle \n";
	ok(0) if (! $tran_handle);


	$rc=Perf::ARM::arm_stop($tran_handle, 0, 0,0,0);
	printf "%3.3d: ",$i;
	print "arm_stop()  transaction app_id:$app_id " .
	    "tran_handle: $tran_handle rc=$rc\n";

	ok(0) if ($rc);
    }

    $rc=Perf::ARM::arm_end($app_id, 0,0,0);

if ($rc) {
    ok(0);
} else {
    ok(1);
}
