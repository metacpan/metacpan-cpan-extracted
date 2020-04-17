use Mojo::Base -strict;
use Test::More;

use Mojo::UserAgent;

my $ua = Mojo::UserAgent->new;

my $tx = $ua->build_tx(GET => '/abc');
is $tx->req->headers->header('X-Mojo-Signature'), undef, 'unsigned request';
is $tx->req->url, '/abc', 'right unsigned url';

$ua = Mojo::UserAgent->with_roles('+Signature')->new;
$ua->initialize_signature('Whatev');

$tx = $ua->build_tx(GET => '/abc');
is $tx->req->headers->header('X-Mojo-Signature'), 'None', 'signed request';

$tx = $ua->build_tx(GET => '/abc' => 'sign');
is $tx->req->headers->header('X-Mojo-Signature'), 'None', 'signed request';

done_testing;