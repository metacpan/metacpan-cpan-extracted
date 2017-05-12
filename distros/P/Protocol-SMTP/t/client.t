use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Protocol::SMTP::Client;

my $smtp = Protocol::SMTP::Client->new;
# Make sure our API methods are still around
can_ok($smtp, qw(
	new login send body_encoding send_mail has_feature
	starttls send_greeting startup wait_for add_task
));

done_testing;
