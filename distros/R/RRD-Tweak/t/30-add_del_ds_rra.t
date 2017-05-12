#!perl -T

use strict;
use warnings;

use Test::More tests => 13;

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
eval { $rrd1->add_ds({name => 'InOctets',
                      type=> 'COUNTER',
                      heartbeat => 600}) };
ok($@, "add_ds with duplicate name") or
    BAIL_OUT('added a DS with duplicate name, but did not get an error');

ok($rrd1->validate(), "validate()") or diag($rrd1->errmsg());

$rrd1->add_ds({name => 'InErrors',
               type=> 'COUNTER',
               heartbeat => 755});

ok($rrd1->validate(), "validate()") or diag($rrd1->errmsg());

$rrd1->del_ds(1);

ok($rrd1->validate(), "validate()") or diag($rrd1->errmsg());

my $rrd1_info = $rrd1->info();

ok((scalar(@{$rrd1_info->{ds}}) == 3),
   'after adding and deleting DS, should get 3 datasources');


ok(($rrd1_info->{ds}[2]{heartbeat} == 755),
    '$rrd1_info->{ds}[2]{heartbeat}) == 755');


# check the edge case: duplicate RRA
eval { $rrd1->add_rra({cf => 'MAX',
                       xff => 0.77,
                       steps => 12,
                       rows => 1010}) };
ok($@, "add_rra with duplicate RRA") or
    BAIL_OUT('added RRA with duplicate CF and steps, but did not get an error');

$rrd1->add_rra({cf => 'MIN',
                xff => 0.3,
                steps => 288,
                rows => 768});

ok($rrd1->validate(), "validate()") or diag($rrd1->errmsg());

$rrd1->del_rra(1);

ok($rrd1->validate(), "validate()") or diag($rrd1->errmsg());

$rrd1_info = $rrd1->info();

ok((scalar(@{$rrd1_info->{rra}}) == 3),
   'after adding a deleting RRA, should get 3 RRAs');


ok(($rrd1_info->{rra}[2]{steps} == 288),
   '$rrd1_info->{rra}[2]{steps} == 288');



# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-continued-statement-offset: 4
# cperl-continued-brace-offset: -4
# cperl-brace-offset: 0
# cperl-label-offset: -2
# End:
