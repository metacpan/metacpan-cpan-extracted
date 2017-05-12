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
# HP-UX note: make sure you've added entries to
#    /var/opt/perf/ttd.conf before trying this
#
#---------------------------------------------------------------------------
    use strict;
    use diagnostics;
    use Perf::ARM;
    use Test;
    BEGIN {plan test=>1}

# for debugging
#	use Devel::Peek;  # setenv PERL_DEBUG_MSTATS 2    to see mem usage

my $debug = 0;

my ($end, $rc, $i);
my ($app_name, $app_id, $app_uid);
my ($tran_name, $tran_id, $tran_handle);

################
    $end =10;

    $app_name="aps_app_$$";
    #$app_name=$0;
    $app_uid="*";

    print "starting app_name=$app_name for app_uid=$app_uid\n";
    $app_id=Perf::ARM::arm_init( $app_name, $app_uid, 0,0,0);
    if ($app_id < 0) {
	die "arm_init() failed [$app_id] : do you have a real " .
	    "libarm installed, or just a NOP version? \n";
    }

    $tran_name = "aps_tran1_$$";
    $tran_id=Perf::ARM::arm_getid($app_id, $tran_name,
	"aps_detail1_$$",0,0,0);

    print "app_name = $app_name \n";
    print "app_id   = $app_id \n";
    print "tran_name = $tran_name \n";
    print "tran_id   = $tran_id \n";

    if ($tran_id < 0) {
	my $reason;
	die "arm_getid() failed, tran_id=$tran_id\n";
    }

    for ( $i=0; $i < $end; $i++ ) {
	$tran_handle=Perf::ARM::arm_start($tran_id, 0,0,0);
	   printf "%3.3d: ",$i;
	print "arm_start() trans app_id:$app_id tran_handle:$tran_handle \n";
	die ("arm_start failed tran_handle=$tran_handle") if (!$tran_handle);

	&do_some_fake_work();

	if ($debug){
	       print "tran_handle: ";
	       Dump ($tran_handle)
	}
	$rc=Perf::ARM::arm_stop($tran_handle, 0, 0,0,0);
	   printf "%3.3d: ",$i;
	print "arm_stop()  trans app_id:$app_id " .
	   "tran_handle:$tran_handle rc=$rc\n";
	ok(0) if ($rc);
    } # end for loop

    $rc=Perf::ARM::arm_end($app_id, 0,0,0);
    ok(0) if ($rc);

ok(1);

sub do_some_fake_work
{
    # looking for small delay
    sleep (int(rand(3))); # sleep 0, 1, or 2 seconds
}
