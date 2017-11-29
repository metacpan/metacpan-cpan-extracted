use strict;
use Test::More;
use_ok('Mojo::SMTP::Client');

my $smtp = Mojo::SMTP::Client->new;
ok($smtp, 'SMTP client created');
isa_ok($smtp, 'Mojo::SMTP::Client');

done_testing;
