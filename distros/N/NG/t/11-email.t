use Test::More;
use lib '../lib';
use NG;

SKIP: {
    skip 'no one know your username/password~~', 3;
    mail_get 'pop3.163.com', 'user', 'pass', sub {
        my ( $headers, $body, $num, $pop ) = @_;
        isa_ok $headers, 'Hashtable';
        isa_ok $body, 'Array';
        isa_ok $pop, 'Net::POP3';
    };
};

done_testing();
