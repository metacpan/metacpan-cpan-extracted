# Before `make install' is performed this script should be runnable with
# vim: ts=8 et sw=4 sts=4
# `make test'. After `make install' it should work as `perl Data-AMF-XS.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
my @methods;
use ExtUtils::testlib;
use Storable::AMF3;
use Scalar::Util qw(refaddr);

@methods = @Storable::AMF3::EXPORT_OK;
$totals =  @methods*1 + 1;
eval "use Test::More tests => $totals";


for my $module (qw(Storable::AMF3)){
	ok($module->can($_), "$module can $_") for @methods;
}

eval{
    Storable::AMF3::dclone([]);
    Storable::AMF3::ref_lost_memory([]);
};
ok(!$@, "dclone && ref_lost_memory really defined");

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

