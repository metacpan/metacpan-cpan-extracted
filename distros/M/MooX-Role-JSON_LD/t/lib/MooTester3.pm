package MooTester3;

use Moo;
extends 'MooTester2';

use MooX::JSON_LD 'Another';

use namespace::autoclean;

has zip => (
    is      => 'ro',
    default => 'Pow',
    json_ld => 1,
);


1;
