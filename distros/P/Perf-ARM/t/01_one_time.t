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
# HPUX note: make sure you've added entries to ttd.conf before trying this
#---------------------------------------------------------------------------

    use strict;
    use Perf::ARM;

    use Test;
    BEGIN {plan test =>1}

    my ($app_id,$tran_id,$tran_handle,$rc);

################

    $app_id=Perf::ARM::arm_init( "$0", "*", 0,0,0);
    if ($app_id <=0) {
    ok(0);
	die "arm_init() failed [$app_id]: do you have a real " .
	    "libarm installed, or just a NOP version? \n";
    }


    $tran_id=Perf::ARM::arm_getid($app_id, "simple_tran",
	"detail_$$", 0,0,0);

    if (($tran_id<=0)) {
	ok(0);
	die "arm_getid() failed [$tran_id]: can't have tran_id <=0\n";
    }

    $tran_handle=Perf::ARM::arm_start($tran_id, 0,0,0);

    print "arm_start() app_id:$app_id tran_id:$tran_id" .
	"tran_handle:$tran_handle \n";

    if (($app_id<=0) || ($tran_handle<=0)) {
	ok(0);
	die "arm_start() failed [$tran_handle] can't " .
		"have app_id or tran_handle <=0\n";
    }

    $rc=Perf::ARM::arm_stop($tran_handle, 0, 0,0,0);
    print "arm_stop() app_id:$app_id tran_id:$tran_id" .
	"tran_handle:$tran_handle rc=$rc\n";

    ok(0) if ($rc);

    $rc=Perf::ARM::arm_end($app_id, 0,0,0);

    if ($rc) {
	ok(0);
    } else {
	ok(1); #passed
    }
