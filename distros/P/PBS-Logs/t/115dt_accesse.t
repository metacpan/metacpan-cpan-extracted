use Test::More tests => 41;
#use Test::More "no_plan";

use PBS::Logs::Event;

my $pl = new PBS::Logs::Event([]);
my ($stime,$etime) = ('03/04/2005 11:27:19','03/04/2005 11:27:20');
my ($ssec,$esec) = (1109935639,1109935640);
my ($ret,$err);

my ($st,$et) = $pl->filter_datetime();
ok(! defined $st,			"Undefined start");
ok(! defined $et,			"Undefined end");

is($pl->filter_datetime($stime,$etime),1,"filter_datetime($stime,$etime)");
($st,$et) = $pl->filter_datetime();
cmp_ok($st,'==',$ssec,			"read $stime value");
cmp_ok($et,'==',$esec,			"read end value");

is($pl->filter_datetime('none',$etime),1,"filter_datetime(none,$etime)");
($st,$et) = $pl->filter_datetime();
ok(! defined $st,			"Undefined start");
cmp_ok($et,'==',$esec,			"read $etime value");

is($pl->filter_datetime($stime,'none'),1,"filter_datetime($stime,none)");
($st,$et) = $pl->filter_datetime();
cmp_ok($st,'==',$ssec,			"read $stime value");
ok(! defined $et,			"Undefined end");

is($pl->filter_datetime('none','none'),1,"filter_datetime(none,none)");
($st,$et) = $pl->filter_datetime();
ok(! defined $st,			"Undefined start");
ok(! defined $et,			"Undefined end");

# now use the seconds
is($pl->filter_datetime($ssec,$esec),1,"filter_datetime($ssec,$esec)");
($st,$et) = $pl->filter_datetime();
cmp_ok($st,'==',$ssec,			"read $ssec value");
cmp_ok($et,'==',$esec,			"read end value");

is($pl->filter_datetime('none',$esec),1,"filter_datetime(none,$esec)");
($st,$et) = $pl->filter_datetime();
ok(! defined $st,			"Undefined start");
cmp_ok($et,'==',$esec,			"read $esec value");

is($pl->filter_datetime($ssec,'none'),1,"filter_datetime($ssec,none)");
($st,$et) = $pl->filter_datetime();
cmp_ok($st,'==',$ssec,			"read $ssec value");
ok(! defined $et,			"Undefined end");

is($pl->filter_datetime('none','none'),1,"filter_datetime(none,none)");
($st,$et) = $pl->filter_datetime();
ok(! defined $st,			"Undefined start");
ok(! defined $et,			"Undefined end");

open STDERR, ">015.err" or die;
eval {
	$ret = $pl->filter_datetime($ssec),
};
is($@,"",				"one argument - does not croak");
ok(! defined $ret, 			"filter_datetime($ssec)");
open ERROR, "<015.err" or die;
$err = <ERROR>;
close ERROR;
like($err,qr/PBS::Logs: filter_datetime : received an undefined value at/,
	"only one argument error");

# bad start values
open STDERR, ">015.err" or die;
eval {
	$ret = $pl->filter_datetime("x$ssec",'none');
};
is($@,"",				"bad numeric start - does not croak");
ok(! defined $ret, "filter_datetime(x$ssec,'none')");
open ERROR, "<015.err" or die;
$err = <ERROR>;
close ERROR;
like($err,qr/PBS::Logs: filter_datetime : bad start value = 'x1109935639' at/,
	"bad numeric start error");

open STDERR, ">015.err" or die;
eval {
	$ret = $pl->filter_datetime("x$stime",'none');
};
is($@,"",				"bad datetime start - does not croak");
ok(! defined $ret, "filter_datetime(x$stime,'none')");
open ERROR, "<015.err" or die;
$err = <ERROR>;
close ERROR;
like($err,qr/PBS::Logs: filter_datetime : bad start value = 'x03\/04\/2005 11:27:19' at/,
	"bad datetime start error");

# bad end values
open STDERR, ">015.err" or die;
eval {
	$ret = $pl->filter_datetime('none',"x$esec");
};
is($@,"",				"bad numeric end - does not croak");
ok(! defined $ret, "filter_datetime(x$ssec,'none')");
open ERROR, "<015.err" or die;
$err = <ERROR>;
close ERROR;
like($err,qr/PBS::Logs: filter_datetime : bad end value = 'x1109935640' at/,
	"bad numeric end error");

open STDERR, ">015.err" or die;
eval {
	$ret = $pl->filter_datetime('none',"x$etime");
};
is($@,"",				"bad datetime end - does not croak");
ok(! defined $ret, "filter_datetime(x$stime,'none')");
open ERROR, "<015.err" or die;
$err = <ERROR>;
close ERROR;
like($err,qr/PBS::Logs: filter_datetime : bad end value = 'x03\/04\/2005 11:27:20' at/,
	"bad datetime end error");

unlink("015.err");
