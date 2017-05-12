# vim: ts=8 et sw=4 sts=4
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Data-AMF-XS.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
my @methods;

use ExtUtils::testlib;

use Storable::AMF0;
use Storable::AMF3;
use Storable::AMF;
use Scalar::Util qw(refaddr);
@methods = grep !m/thaw0_sv/,@Storable::AMF::EXPORT_OK;
$totals = ( @methods * 3 - 2 * 4 ) + 2 * 2  + 1  -4  ;
eval "use Test::More tests => $totals";

for my $module (qw(Storable::AMF Storable::AMF0 Storable::AMF3)){
	for (@methods){
		next if m/[03]\z/ && $module ne 'Storable::AMF';
		ok($module->can($_), "$module can $_");
	}
}

my ($m, $n);
($m, $n) = qw(Storable::AMF Storable::AMF0);

is(refaddr $m->can($_), refaddr $n->can($_), "identity for $_ in AMF0") for qw(ref_lost_memory ref-clear);

($m, $n) = qw(Storable::AMF3 Storable::AMF0);

is(refaddr $m->can($_), refaddr $n->can($_), "identity for $_ in AMF3") for qw(ref_lost_memory ref-clear);
eval{
    Storable::AMF0::dclone([]);
    Storable::AMF0::ref_lost_memory([]);
};
ok(!$@);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

