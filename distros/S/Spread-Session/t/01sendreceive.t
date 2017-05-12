use Test::Simple tests => 2;

BEGIN {
    $ENV{LOG_CHANNEL_CONFIG} = "t/logging.xml";
}

use Spread::Session;

my $group = "session_test";

if (fork) {
    # this is the sender

    sleep(1);

    my $session = new Spread::Session;
    $session->callbacks(
			message => sub {
			    my ($sender, $groups, $message) = @_;
			    ok($message eq "response!");
			}
		       );
    $session->publish($group, "test message");
    $session->receive(2);

} else {
    # this is the listener

    my $session = new Spread::Session;
    my $done = 0;
    $session->callbacks(
			message => sub {
			    my ($sender, $groups, $message) = @_;
			    $session->publish($sender, "response!");
			    $done++;
			}
		       );
    $session->subscribe($group);
    while (!$done) {
	$session->receive(2);
    }
    exit;
}

ok(1);
