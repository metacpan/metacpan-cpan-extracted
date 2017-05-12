
use strict;
use 5.008001;

use ExtUtils::MakeMaker;
use Apache::TestMM;

my $apache_tests_default = 'yes';
eval 'use Apache2';
if ($@) {
	$apache_tests_default = 'no';
}

if (not prompt("Would you like me to run tests with your Apache 2.x?",
	$apache_tests_default) =~ /^y/i) {
	print "\tGood. We will only test the core RayApp.\n";
	ExtUtils::MakeMaker::WriteEmptyMakefile(
		NAME => 'No-RayApp-Apache-Tests',
	);
	return;
}

my $buildconfig;
my ($apxs, $modules_lib, $mod_perl_lib);

eval <<'EOF';
	use Apache2::BuildConfig;
	$buildconfig = new Apache2::BuildConfig;
EOF

if (defined $buildconfig) {
	# use Data::Dumper; print Dumper $buildconfig;
	$apxs = $buildconfig->{MP_APXS};
	$modules_lib = $buildconfig->{APXS_LIBEXECDIR};
	$mod_perl_lib = $buildconfig->{MODPERL_AP_LIBEXECDIR};
}

if (not defined $apxs or not -f $apxs or not -x $apxs) {
	$apxs = prompt "Please tell me where your apxs is:", $apxs;
}
if (not $apxs) {
	print "\tWe shall skip the tests, then.\n";
	ExtUtils::MakeMaker::WriteEmptyMakefile(
		NAME => 'No-RayApp-Apache-Tests',
	);
	return;
}

unshift @ARGV, '-apxs', $apxs;
eval q!
	use Apache::TestMM qw( );
	use Apache::Test 1.11;
	Apache::TestMM::filter_args();
	Apache::TestMM::generate_script('t/TEST');
!;
if ($@) {
	print "\tIt looks like you do not have all the modules needed\n\tto run Apache tests:\n$@\n";
	ExtUtils::MakeMaker::WriteEmptyMakefile(
		NAME => 'No-RayApp-Apache-Tests',
	);
	return;
}

print "\tGood. We will run tests using your Apache [$apxs]\n\twith mod_perl library in [$mod_perl_lib]\n";
symlink 'ray', 't/htdocs/ray1';
symlink 'ray', 't/htdocs/ray2';

sub MY::test {
	package MY;
	return Apache::TestMM->test(@_);
}

WriteMakefile(
	NAME => 'RayApp-Apache-Tests',
	test => {
		TESTS => 't/TEST',
	},
        clean => {
                FILES => 't/TEST t/htdocs/ray1 t/htdocs/ray2 t/conf/apache_test_config.pm t/conf/extra.conf t/conf/httpd.conf t/logs t/htdocs/ray/changing.mpl',
        },
);

