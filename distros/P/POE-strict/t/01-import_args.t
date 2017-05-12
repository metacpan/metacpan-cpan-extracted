
use Test::More qw(no_plan);


use POE::strict qw(
	Component::Client::TCP
);

eval {
	unless(POE::Component::Client::TCP->can('new')) {
		die "CRAP";
	}
};

is($@,'',"loaded Client::TCP just fine");
