# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Options.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;

BEGIN { 
		use_ok('Properties');
		use_ok('Merror');
		use_ok('strict');
		use_ok('warnings');
		use_ok('File::Spec');
		use_ok('File::Basename');
		use_ok('Data::Dumper');
};

#########################

subtest 'Example' => sub {
		use File::Spec;
		use File::Basename;
		my $file = File::Spec->rel2abs(dirname($0))."/props";
		my $opts = Properties->new($file);
		is($opts->error, 0, 'constructing object');
		is($opts->getProperty("socket.local.port"), "3333", 'fetching property');
		
		my $secondfile = "bliblablub0815foobar";
		my $opts2 = Properties->new($secondfile);
		is($opts2->error, 1, 'error construction');
		
		my $hash = $opts->getCompleteConfig();
		is($opts->error, 0, 'fetching complete config');
		
		done_testing($number_of_tests);
};

subtest 'Neq_Example' => sub {
	use File::Spec;
	use File::Basename;
	use Data::Dumper;
	my $file = File::Spec->rel2abs(dirname($0))."/neq_props";
	my $opts = Properties->new($file);
	is($opts->error, 0, 'constructing object');
	is($opts->getProperty("socket.local.hostname"), "localhost.de.com", 'fetching property');
	is($opts->getProperty("socket.remote.hostname"), "remotehost.de.com", 'fetching property');
	done_testing($number_of_tests);
};
done_testing($number_of_tests);

