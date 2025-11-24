#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
        use_ok('RRD::Fetch') || print "Bail out!\n`";
}

my $worked = 0;
eval {
	my $rrd_fetch=RRD::Fetch->new(rrd_file=>'t/data/ucd_load.rrd');
	if ($rrd_fetch->{CF} ne 'AVERAGE'){
		die('default $rrd_fetch->{CF} not set to AVERAGE');
	}
	if (defined($rrd_fetch->{resolution})){
		die('default $rrd_fetch->{resolution} not set to undef');
	}
	if ($rrd_fetch->{retries} ne '3'){
		die('default $rrd_fetch->{retries} not set to 3');
	}
	if ($rrd_fetch->{backoff} ne '1'){
		die('default $rrd_fetch->{backoff} not set to 1');
	}
	$worked = 1;
};
ok( $worked eq '1', 'new good' ) or diag( "new good test died with ... " . $@ );

$worked = 0;
eval {
	my $rrd_fetch=RRD::Fetch->new(rrd_file=>'t/data/ucd_load.rrd', CF=>'AVERAGE');
	if ($rrd_fetch->{CF} ne 'AVERAGE'){
		die('$rrd_fetch->{CF} not set to AVERAGE');
	}
	$worked = 1;
};
ok( $worked eq '1', 'new good cf average' ) or diag( "new good cf average test died with ... " . $@ );

$worked = 0;
eval {
	my $rrd_fetch=RRD::Fetch->new(rrd_file=>'t/data/ucd_load.rrd', CF=>'MIN');
	if ($rrd_fetch->{CF} ne 'MIN'){
		die('$rrd_fetch->{CF} not set to MIN');
	}
	$worked = 1;
};
ok( $worked eq '1', 'new good cf min' ) or diag( "new good cf min test died with ... " . $@ );

$worked = 0;
eval {
	my $rrd_fetch=RRD::Fetch->new(rrd_file=>'t/data/ucd_load.rrd', CF=>'MAX');
	if ($rrd_fetch->{CF} ne 'MAX'){
		die('$rrd_fetch->{CF} not set to MAX');
	}
	$worked = 1;
};
ok( $worked eq '1', 'new good cf max' ) or diag( "new good cf max test died with ... " . $@ );

$worked = 0;
eval {
	my $rrd_fetch=RRD::Fetch->new(rrd_file=>'t/data/ucd_load.rrd', CF=>'LAST');
	if ($rrd_fetch->{CF} ne 'LAST'){
		die('$rrd_fetch->{CF} not set to LAST');
	}
	$worked = 1;
};
ok( $worked eq '1', 'new good cf last' ) or diag( "new good cf last test died with ... " . $@ );

$worked = 0;
eval {
	my $rrd_fetch=RRD::Fetch->new(rrd_file=>'t/data/ucd_load.rrd', retries=>333);
	if ($rrd_fetch->{retries} ne '333'){
		die('$rrd_fetch->{retries} not set to 333');
	}
	$worked = 1;
};
ok( $worked eq '1', 'new good retries' ) or diag( "new good restries test died with ... " . $@ );

$worked = 0;
eval {
	my $rrd_fetch=RRD::Fetch->new(rrd_file=>'t/data/ucd_load.rrd', retries=>0);
	if ($rrd_fetch->{retries} ne '0'){
		die('$rrd_fetch->{retries} not set to 0');
	}
	$worked = 1;
};
ok( $worked eq '1', 'new good no retries' ) or diag( "new good no restries test died with ... " . $@ );

$worked = 0;
eval {
	my $rrd_fetch=RRD::Fetch->new(rrd_file=>'t/data/ucd_load.rrd', resolution=>333);
	if ($rrd_fetch->{resolution} ne '333'){
		die('$rrd_fetch->{resolution} not set to 333');
	}
	$worked = 1;
};
ok( $worked eq '1', 'new good resolution' ) or diag( "new good resolution test died with ... " . $@ );

$worked = 0;
eval {
	my $rrd_fetch=RRD::Fetch->new(rrd_file=>'t/data/ucd_load.rrd', backoff=>333);
	if ($rrd_fetch->{backoff} ne '333'){
		die('$rrd_fetch->{backoff} not set to 333');
	}
	$worked = 1;
};
ok( $worked eq '1', 'new good backoff' ) or diag( "new good backoff test died with ... " . $@ );

$worked = 0;
eval {
	my $rrd_fetch=RRD::Fetch->new(rrd_file=>'t/data/ucd_load.rrd', CF=>'MIN', backoff=>333, resolution=>22,retries=>1, align=>0);
	if ($rrd_fetch->{backoff} ne '333'){
		die('$rrd_fetch->{backoff} not set to 333');
	}
	if ($rrd_fetch->{resolution} ne '22'){
		die('$rrd_fetch->{resolution} not set to 22');
	}
	if ($rrd_fetch->{CF} ne 'MIN'){
		die('$rrd_fetch->{CF} not set to MIN');
	}
	if ($rrd_fetch->{retries} ne '1'){
		die('$rrd_fetch->{retries} not set to 1');
	}
	if ($rrd_fetch->{align} ne '0'){
		die('$rrd_fetch->{align} not set to 0');
	}
	$worked = 1;
};
ok( $worked eq '1', 'new good multi' ) or diag( "new good multi test died with ... " . $@ );

$worked = 0;
eval {
	my $rrd_fetch=RRD::Fetch->new(rrd_file=>'t/data/ucd_load.rrd', CF=>'derp');
	$worked = 1;
};
ok( $worked eq '0', 'new bad cf' ) or diag( 'new accepts improper values for CF' );

$worked = 0;
eval {
	my $rrd_fetch=RRD::Fetch->new(rrd_file=>'t/data/ucd_load.rrd', resolution=>'derp');
	$worked = 1;
};
ok( $worked eq '0', 'new bad resolution' ) or diag( 'new accepts improper values for resolution' );

$worked = 0;
eval {
	my $rrd_fetch=RRD::Fetch->new(rrd_file=>'t/data/ucd_load.rrd', retries=>'derp');
	$worked = 1;
};
ok( $worked eq '0', 'new bad retries' ) or diag( 'new accepts improper values for retries' );

$worked = 0;
eval {
	my $rrd_fetch=RRD::Fetch->new(rrd_file=>'t/data/ucd_load.rrd', backoff=>'derp');
	$worked = 1;
};
ok( $worked eq '0', 'new bad backoff' ) or diag( 'new accepts improper values for backoff' );

done_testing(15);
