use warnings;
use strict;
use feature 'say';

use Tesla::API;
use Test::More;

my $t = Tesla::API->new(unauthenticated => 1);

my $verifier = $t->_authentication_code_verifier;

my $url = $t->_authentication_code_url;

like
    $url,
    qr/$verifier/,
    "Code verifier in URL ok";

like
    $url,
    qr/state=123/,
    "state covered in URL ok";

like
    $url,
    qr/client_id=ownerapi/,
    "client_id covered in URL ok";

done_testing();