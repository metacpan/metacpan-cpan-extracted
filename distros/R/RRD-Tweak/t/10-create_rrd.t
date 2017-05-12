#!perl -T

use strict;
use warnings;

use Test::More tests => 9;

use File::Temp qw/tmpnam/;
use RRDs;
use Data::Compare;
use Data::Dumper;

BEGIN {
  use_ok('RRD::Tweak', "use RRD::Tweak") or
    BAIL_OUT("cannot load the module");
}

diag("Testing RRD::Tweak $RRD::Tweak::VERSION, Perl $], $^X");

my $filename1 = tmpnam();

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

diag("Saving $filename1");
$rrd1->save_file($filename1);
ok(not $@);
diag("Saved $filename1");

my $rrd1_info = $rrd1->info();
ok((ref($rrd1_info) eq 'HASH'), '$rrd1->info() returned a hashref');

my $rrd2 = RRD::Tweak->new();
ok((defined($rrd2)), "RRD::Tweak->new()");

eval { $rrd2->load_file($filename1) };
ok((not $@), '$rrd2->load_file($filename1)') or
    BAIL_OUT("load_file failed: " . $@);

my $rrd2_info = $rrd2->info();
ok((ref($rrd2_info) eq 'HASH'), '$rrd2->info() returned a hashref');

if( not ok(Compare($rrd1_info, $rrd2_info),
           'Compare($rrd1_info, $rrd2_info)') ) {
    diag(Dumper($rrd1_info));
    diag(Dumper($rrd2_info));
}

# print Dumper($rrd2->{cdp_data});

ok((unlink $filename1), "unlink $filename1");




# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-continued-statement-offset: 4
# cperl-continued-brace-offset: -4
# cperl-brace-offset: 0
# cperl-label-offset: -2
# End:
