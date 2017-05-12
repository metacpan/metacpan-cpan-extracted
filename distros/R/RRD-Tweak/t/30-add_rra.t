#!perl -T

use strict;
use warnings;

use Test::More tests => 12;

use File::Temp qw/tmpnam/;
use RRDs;
use Data::Dumper;

BEGIN {
  use_ok('RRD::Tweak', "use RRD::Tweak") or
    BAIL_OUT("cannot load the module");
}

diag("Testing RRD::Tweak $RRD::Tweak::VERSION, Perl $], $^X");

my $filename1 = tmpnam();
my $filename2 = tmpnam();

# 1326585600 = Sun Jan 15 01:00:00 2012
RRDs::create($filename1, '--step', '300',
             '--start', '1326585600',
             'DS:x1:GAUGE:600:-1e10:1e15',
             'DS:x2:GAUGE:600:0.0001:U',
             'RRA:AVERAGE:0.5:1:1200',
             'RRA:HWPREDICT:1440:0.1:0.0035:288:3',
             'RRA:SEASONAL:288:0.1:2',
             'RRA:DEVPREDICT:1440:5',
             'RRA:DEVSEASONAL:288:0.1:2',
             'RRA:FAILURES:288:7:9:5',
             'RRA:MIN:0.5:12:2400',
             'RRA:MAX:0.5:12:2400',
             'RRA:AVERAGE:0.5:12:2400');

my $err = RRDs::error();
ok((not $err), "creating RRD file: $filename1") or
  BAIL_OUT("Cannot create RRD file: " . $err);

RRDs::update($filename1,
             '1326585900:300:400',
             '1326586200:400:500',
             '1326586500:500:600',
             '1326586800:600:700',
             '1326587100:600:700',
             '1326587400:600:700',
             '1326587700:600:700',
             '1326588000:600:700',
             '1326588300:600:700',
             '1326588600:600:700',
             '1326588900:600:700',
             '1326589200:600:700',
             '1326589500:600:700',
             '1326589800:600:700',
             '1326590100:600:700',
             '1326590400:600:700',
             '1326590700:600:700',
             '1326591000:600:700',
             '1326591300:600:700',
             '1326591600:600:700',
             '1326591900:600:700',
             '1326592200:600:700',
             '1326592500:600:700',
            );

$err = RRDs::error();
ok((not $err), "updating RRD file: $filename1") or
    BAIL_OUT("Cannot update RRD file: " . $err);

diag("Created $filename1");

my $rrd1 = RRD::Tweak->new();
$rrd1->load_file($filename1);
ok($rrd1->validate(), "validate()") or diag($rrd1->errmsg());

$rrd1->add_rra({cf => 'AVERAGE',
                xff => 0.25,
                steps => 6,
                rows => 5});

$rrd1->add_rra({cf => 'MIN',
                xff => 0.25,
                steps => 6,
                rows => 5});


$rrd1->save_file($filename2);
diag("Saved $filename2");

$rrd1->clean();
$rrd1->load_file($filename1);
ok($rrd1->validate(), "validate()") or diag($rrd1->errmsg());

my $rrd2 = RRD::Tweak->new();
$rrd2->load_file($filename2);
ok($rrd2->validate(), "validate()") or diag($rrd2->errmsg());

#diag(Dumper($rrd2->{cdp_data}[9]));
#diag(Dumper($rrd2->{cdp_data}[10]));

ok($rrd2->{cdp_data}[9][1][0] == 480);
ok($rrd2->{cdp_data}[10][1][0] == 300);

ok($rrd2->{cdp_data}[9][2][0] == 600);
ok($rrd2->{cdp_data}[10][2][0] == 600);

ok((unlink $filename1), "unlink $filename1");
ok((unlink $filename2), "unlink $filename2");




# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-continued-statement-offset: 4
# cperl-continued-brace-offset: -4
# cperl-brace-offset: 0
# cperl-label-offset: -2
# End:
