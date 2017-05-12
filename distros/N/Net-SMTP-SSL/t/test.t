use Test::More tests => 1;
require Net::SMTP::SSL;

ok(Net::SMTP::SSL->isa('Net::SMTP'));
