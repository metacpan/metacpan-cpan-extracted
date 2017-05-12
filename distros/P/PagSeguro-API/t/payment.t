use strict;

use Test::More;

use PagSeguro::API;


BEGIN { use_ok 'PagSeguro::API::Payment' }

subtest 'payment instance' => sub {
    my $p = PagSeguro::API::Payment->new;
    isa_ok $p, 'PagSeguro::API::Payment';
};


subtest 'payment constructor' => sub {
    my $p = PagSeguro::API->new;
    $p->email('foo');
    $p->token('bar');

    my $payment = $p->payment_request;
    
    is $payment->email, 'foo';
    is $payment->token, 'bar';

    $payment = PagSeguro::API::Payment->new;
    $payment->email('bar');
    $payment->token('baz');

    is $payment->email, 'bar';
    is $payment->token, 'baz';
};


subtest 'pagseguro payment accessors' => sub {
    my $payment = PagSeguro::API::Payment->new;
    $payment->reference('foo');
    $payment->notification_url('bar');
    $payment->redirect_url('baz');

    is $payment->reference,'foo';
    is $payment->notification_url,'bar';
    is $payment->redirect_url,'baz';
};
    
my $payment = PagSeguro::API::Payment->new;
$payment->email('for');
$payment->token('bar');

subtest 'pagseguro payment add item' => sub {
    $payment->add_item(
        id          => 1,
        description => 'product foo bar',
        amount      => '1.00',
        weight      => '0.100',
    );

    is int(@{$payment->items}), 1;

    my $item = $payment->item(1);
    is $item->{id}, 1;
    is $item->{description}, 'product foo bar';
};

subtest 'pagseguro payment request' => sub {
    $payment->add_item(
        id          => 1,
        description => 'product foo bar',
        amount      => '1.00',
        weight      => '0.100',
    );

    my $response = $payment->request;

    ok $response;
};    

done_testing;
