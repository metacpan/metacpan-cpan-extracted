use PagSeguro::API;

# new instance
my $p = PagSeguro::API->new;

#configure
$p->email('RECEIVER EMAIL');
$p->token('RECEIVER TOKEN');
$p->environment('sandbox');


# new payment object by (PagSeguro::API) wrapper
my $payment = $p->payment_request;

$payment->reference('2');
$payment->notification_url('http://google.com');
$payment->redirect_url('http://url_of_love.com.br');


# add items
$payment->add_item(
    id          => 1,
    description => 'test od love',
    amount      => '1.00',
);
$payment->add_item(
    id          => 2,
    description => 'test od love 2',
    amount      => '1.00',
);


my $response = $payment->request;

## you can use form button too
#print $payment->request_form( 
#    text   => 'Finalizar', 
#    class  => 'btn btn-default' 
#);


# error
warn "Error: ". $response->error if $response->error;

# now redirect user for pagseguro payment url
use Data::Dumper;
print Dumper $response->data

