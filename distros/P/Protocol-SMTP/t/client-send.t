use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Protocol::SMTP::Client;

my $smtp = Protocol::SMTP::Client->new;
like(exception {
	$smtp->send_mail
}, qr/Must specify either data or content/, 'exception raised when no data or content present');
like(exception {
	$smtp->send_mail(data => 1, content => 1)
}, qr/Must specify either data or content/, 'exception raised when both data or content present');

done_testing;
