

use Data::Dumper;
use PagSeguro::API;

# new instance
my $p = PagSeguro::API->new;

#configure
$p->email('RECEIVER EMAIL');
$p->token('RECEIVER TOKEN');
$p->environment('sandbox');

# new transaction
my $transaction = $p->transaction;

# getting by code
print Dumper $transaction->by_code('D0BDD600686447059D9337FEC40BCA2D');

# getting by notification code
print Dumper $transaction->by_notification_code('24B7AFF0333B333B392FF4D3CF8A444511A1');

# error
#warn "Error: ". $response->error if $response->error;

