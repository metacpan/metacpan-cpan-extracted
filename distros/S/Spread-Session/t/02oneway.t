use Test;
BEGIN { plan tests => 2 }

use Spread::Session;

if (defined eval { require Log::Channel }) {
    disable Log::Channel "Spread::Session";
}

my $group = "session_test";

if (fork) {
    # this is the sender

    sleep(1);

    my $session = new Spread::Session;
    $session->publish($group, "test message");
    exit;

} else {
    # this is the listener

    my $session = new Spread::Session;
    my $done = 0;
    $session->callbacks(
			message => sub {
			    my ($sender, $groups, $message) = @_;
			    ok($message eq "test message");
			    $done++;
			}
		       );
    $session->subscribe($group);
    while (!$done) {
	$session->receive(2);
    }
}

ok(1);
