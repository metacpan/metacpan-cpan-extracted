#!perl -T

use strict;
use warnings;

use Test::More tests => 8;

use File::Temp qw/tmpnam/;
use RRDs;
use Data::Dumper;

BEGIN {
  use_ok('RRD::Tweak', "use RRD::Tweak") or
    BAIL_OUT("cannot load the module");
}

diag("Testing RRD::Tweak $RRD::Tweak::VERSION, Perl $], $^X");

my $filename1 = tmpnam();

# 1326585600 = Sun Jan 15 01:00:00 2012
RRDs::create($filename1, '--step', '300',
             '--start', '1326585600',
             'DS:x1:GAUGE:600:-1e10:1e15',
             'DS:x2:GAUGE:600:0.0001:U',
             
             'RRA:AVERAGE:0.5:1:1200',
             'RRA:AVERAGE:0.5:12:2400',
             
             'RRA:HWPREDICT:1440:0.1:0.0035:288',
             
             'RRA:MIN:0.5:12:2400',
             'RRA:MAX:0.5:12:2400',
             );

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
            );

$err = RRDs::error();
ok((not $err), "updating RRD file: $filename1") or
    BAIL_OUT("Cannot update RRD file: " . $err);


my $rrd = RRD::Tweak->new();
ok((defined($rrd)), "RRD::Tweak->new()");

diag("\$rrd->load_file($filename1)");
$rrd->load_file($filename1);

$rrd->del_rra(1);
$rrd->del_rra(7);

my $info = $rrd->info();
ok(scalar(@{$info->{rra}}) == 7) or
    diag('Wrong number of RRA: ' . scalar(@{$info->{rra}}) . ', expected 7');

ok($info->{rra}[1]{'dependent_rra_idx'} == 2) or
    diag('{rra}[1]{dependent_rra_idx} != 2');

ok($info->{rra}[2]{'dependent_rra_idx'} == 1) or
    diag('{rra}[2]{dependent_rra_idx} != 1');


#my $filename2 = tmpnam();
#diag("Saving $filename2");
#$rrd->save_file($filename2);
#diag("Saved $filename2");


ok((unlink $filename1), "unlink $filename1");
#ok((unlink $filename2), "unlink $filename2");




# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-continued-statement-offset: 4
# cperl-continued-brace-offset: -4
# cperl-brace-offset: 0
# cperl-label-offset: -2
# End:
