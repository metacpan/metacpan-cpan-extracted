

use Data::Dumper;
use PagSeguro::API;

# new instance
my $p = PagSeguro::API->new;

#configure
$p->email('RECEIVER EMAIL');
$p->token('RECEIVER TOKEN');
$p->environment('sandbox');

# new transaction
my $notification = $p->notification;

print Dumper $notification->by_code('24B7AFF0333B333B392FF4D3CF8A444511A1');

# error
#warn "Error: ". $response->error if $response->error;


