# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 10 };
use Redirx::Client;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

$DEBUG = 0;

my $badClient = eval { Redirx::Client->new({Host => 'maz.org',
					    Debug => $DEBUG}) };
ok($@);
ok(! $badClient);

my $goodClient = eval { Redirx::Client->new({Debug => $DEBUG}) };
ok(! $@);
ok($goodClient);

ok($goodClient->ping());

my $badUrl = eval { $goodClient->storeUrl("hi") };
ok($@ && $@ =~ /MALFORMED_URL/);
ok(! $badUrl);

my $goodUrl = eval { $goodClient->storeUrl("http://www.maz.org/") };
ok(! $@);
ok($goodUrl);
