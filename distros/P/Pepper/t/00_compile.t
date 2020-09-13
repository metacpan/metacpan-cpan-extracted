use strict;
use Test::More tests => 11;

# proceed to test the Pepper code
use_ok $_ for qw(
	Pepper
);

# make sure all the subordinate packages work too
foreach my $lib ('PlackHandler','DB','Utilities','Commander','Templates') {
	require_ok 'Pepper::'.$lib;
}

# double-test utilities
my $pepper_utils = Pepper::Utilities->new({
	'skip_db' => 1,
	'skip_config' => 1,
});

isa_ok( $pepper_utils, 'Pepper::Utilities' );

my @util_methods = ('send_response','template_process','logger','filer','json_from_perl','json_to_perl','random_string','time_to_date');
can_ok('Pepper::Utilities', @util_methods);

# make sure /opt is there
my $opt_is_there = 0;
	$opt_is_there = 1 if (-d '/opt');
ok($opt_is_there, '/opt exists');

# let's test template_process() and time_to_date() in one action
my $pepper_templates = Pepper::Templates->new();
my $test_template = $pepper_templates->get_template('test_template');
my $test_output = $pepper_utils->template_process({
	'template_text' => $test_template,
	'template_vars' => {
		'test_date' => '2002-04-12',
		'test_day' => $pepper_utils->time_to_date('2002-04-12','to_day_of_week')
	},
});
ok($test_output, '2002-04-12 was a Friday');

# test our JSON parser
my $sample_data = {
	'Ginger' => {
		'born' => 1999,
		'lived_to' => 19.75,
	},
	'Pepper' => {
		'born' => 2002,
		'lived_to' => 14,
	},
};

my $sample_json = $pepper_utils->json_from_perl($sample_data);
my $test_data = $pepper_utils->json_to_perl($sample_json);

ok( $$sample_data{Ginger}{lived_to}, $$test_data{Ginger}{lived_to} );

done_testing;

