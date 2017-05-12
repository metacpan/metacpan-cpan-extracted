use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Protocol::SMTP::Client;

{
	package Local::MyFuture;
	use parent qw(Future);
}
my $written = '';
# Sidestep line ending annoyances
sub line() {
	return $1 if $written =~ s/^(.*?)\x0D\x0A//;
	return undef;
}
# Future wrapper - avoid tiresome failure checks
sub unmei($;$) {
	my $f = shift;
	my $msg = shift // '';
	$f->on_done(sub { pass("$f succeeded - $msg") })
	->on_fail(sub { fail("$f failed (" . $f->failure . ") - $msg") })
	->on_cancel(sub { note "$f was cancelled - $msg" })
}
my $smtp = Protocol::SMTP::Client->new(
	future_factory => sub { Local::MyFuture->new },
	writer => sub {
		$written .= shift;
		Local::MyFuture->wrap
	},
);
ok(!exception { $smtp->startup }, 'no exception thrown on initial startup');
is($written, '', 'no bytes written yet');
ok(!exception { $smtp->handle_line('220 localhost') }, 'receive initial 220 from server');
ok(!exception { $smtp->send_greeting }, 'no exception when sending the greeting');
is(line, 'EHLO localhost', 'have EHLO line');
ok(!exception { $smtp->handle_line('250-localhost') }, 'can handle response without exception');
is($written, '', 'no bytes written yet');
ok(!exception { $smtp->handle_line('250-SIZE 10240000') }, 'can handle response without exception');
is($written, '', 'no bytes written yet');
ok(!exception { $smtp->handle_line('250-8BITMIME') }, 'can handle response without exception');
is($written, '', 'no bytes written yet');
ok(!exception { $smtp->handle_line('250-AUTH PLAIN LOGIN DIGEST-MD5') }, 'can handle response without exception');
is($written, '', 'no bytes written yet');
ok(!exception { $smtp->handle_line('250 STARTTLS') }, 'can handle response without exception');
is($written, '', 'no bytes written yet');
ok(!exception { unmei($smtp->login(
	user => 'username',
	pass => 'password',
)) }, 'attempt login, have no exception');
is(line, 'AUTH DIGEST-MD5 ', 'attempted DIGEST-MD5 auth');
done_testing;
