
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use Test2::V0;
use PAGI::App::GoldenCage;
use PAGI::Test::Client;

################################################################################
# This live-tests with default poison fountain link
################################################################################

sub is_status
{
	my ($res, $wanted, $name) = @_;

	is $res->status, $wanted, $name;
	if ($res->status != $wanted) {
		diag $res->exception;
	}
}

my $app = PAGI::App::GoldenCage->new();

my $client = PAGI::Test::Client->new(
	app => $app->to_app,
	lifespan => 1,
);

$client->start;

my $res = $client->get($app->generate_link);
is_status $res, 200, 'code ok';
if ($res->content =~ m{<code>(.+?)</code>}s) {
	note "fetched poisoned data: $1";
	pass 'code snippet found';
}
else {
	fail 'could not find code snippet data';
}

done_testing;
