#!perl -T

use strict;
use warnings;

use Test::More tests => 12;

use File::Temp qw/tmpnam/;
use RRDs;
use Data::Compare;
use Data::Dumper;

BEGIN {
  use_ok('RRD::Tweak', "use RRD::Tweak") or
    BAIL_OUT("cannot load the module");
}

diag("Testing RRD::Tweak $RRD::Tweak::VERSION, Perl $], $^X");

my $rrd1 = RRD::Tweak->new();
ok((defined($rrd1)), "RRD::Tweak->new()");

$rrd1->create({step => 300,
              start => time(),
              ds => [{name => 'InOctets',
                      type=> 'COUNTER',
                      heartbeat => 600},
                     {name => 'OutOctets',
                      type => 'COUNTER',
                      heartbeat => 600},
                     {name => 'Load',
                      type => 'GAUGE',
                      heartbeat => 800,
                      min => 0,
                      max => 255}],
              rra => [{cf => 'AVERAGE',
                       xff => 0.5,
                       steps => 1,
                       rows => 2016},
                      {cf => 'AVERAGE',
                       xff => 0.25,
                       steps => 12,
                       rows => 768},
                      {cf => 'MAX',
                       xff => 0.25,
                       steps => 12,
                       rows => 768}]});

diag("created RRD::Tweak with new RRD data");

# check the edge case: duplicate DS name
eval { $rrd1->modify_ds(1, {name => 'InOctets'}) };
ok($@, "modify_ds with duplicate name") or
    BAIL_OUT('modified a DS with duplicate name, but did not get an error');

ok($rrd1->validate(), "validate()") or diag($rrd1->errmsg());

$rrd1->modify_ds(1, {name => 'XXX'});
ok($rrd1->validate(), "validate()") or diag($rrd1->errmsg());
my $rrd1_info = $rrd1->info();
ok(($rrd1_info->{ds}[1]{name} eq 'XXX'), "modify_ds changing name");

# edge case: invalid type
eval { $rrd1->modify_ds(1, {type => 'GAG'}) };
ok($@, "modify_ds with invalid type") or
    BAIL_OUT('modified a DS with invalid type, but did not get an error');

ok($rrd1->validate(), "validate()") or diag($rrd1->errmsg());

$rrd1->modify_ds(1, {type => 'GAUGE'});
ok($rrd1->validate(), "validate()") or diag($rrd1->errmsg());
$rrd1_info = $rrd1->info();
ok(($rrd1_info->{ds}[1]{type} eq 'GAUGE'), "modify_ds changing type");


$rrd1->modify_ds(2, {max => 1000});
ok($rrd1->validate(), "validate()") or diag($rrd1->errmsg());
$rrd1_info = $rrd1->info();
ok(($rrd1_info->{ds}[2]{max} == 1000), "modify_ds changing max");

    


# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-continued-statement-offset: 4
# cperl-continued-brace-offset: -4
# cperl-brace-offset: 0
# cperl-label-offset: -2
# End:
