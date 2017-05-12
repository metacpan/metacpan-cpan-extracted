use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Protocol::SMTP::Client;

my $smtp = new_ok('Protocol::SMTP::Client');
ok(!$smtp->have_active_task, 'no active task yet');
$smtp->add_task(sub {
	ok($smtp->have_active_task, 'we are active, and as such there is an active task');
	pass('task executed');
	Future->wrap;
});
ok(!$smtp->have_active_task, 'we are no longer active');
done_testing;
