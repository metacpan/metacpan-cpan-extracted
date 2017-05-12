use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Protocol::SMTP::Client;

{
	my $smtp = Protocol::SMTP::Client->new;
	is($smtp->body_encoding, '8BITMIME', 'default encoding is 8BITMIME');
}

done_testing;

