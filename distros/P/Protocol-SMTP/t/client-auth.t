use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Protocol::SMTP::Client;

my $smtp = Protocol::SMTP::Client->new;
{
	isa_ok(my $f = $smtp->login, 'Future');
	like($f->failure, qr/no auth/, 'cannot login without some auth mechanisms');
}

done_testing;


