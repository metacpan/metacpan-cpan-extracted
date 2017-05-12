use Test;
BEGIN { plan tests => 2 }

use Spread::Session;
use Data::Dumper;

if (defined eval { require Log::Channel }) {
    disable Log::Channel "Spread::Session";
}

my $group = "session_test";

if (fork) {
    # parent; this is the sender

    sleep(1);

    my $session = new Spread::Session (
				       MESSAGE_CALLBACK => sub {
			    my ($container) = @_;
			    ok($container->{BODY} eq "response!");
			},
				      TIMEOUT => 2,
		       );
    $session->publish($group, "test message");
    $session->receive;

} else {
    # child; this is the listener

    my $done = 0;
    my $session = new Spread::Session(
				      MESSAGE_CALLBACK => sub {
			    my ($container) = @_;
			    $container->{SESSION}->publish($container->{SENDER},
					      "response!");
			    $done++;
			},
				      TIMEOUT => 2,
		       );
    $session->subscribe($group);
    while (!$done) {
	$session->receive;
    }
    exit;
}

ok(1);
