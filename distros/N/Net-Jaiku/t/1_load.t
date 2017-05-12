use Test::More tests => 2;
BEGIN { use_ok('Net::Jaiku') };

SKIP: {
	skip "Please set environment variables JAIKU_USER and JAIKU_KEY to run these tests", 1
		unless $ENV{JAIKU_USER} && $ENV{JAIKU_KEY};

	$jaiku = Net::Jaiku->new(
		username => $ENV{JAIKU_USER},
		userkey  => $ENV{JAIKU_KEY}
	);

	isa_ok($jaiku, 'Net::Jaiku');
}
