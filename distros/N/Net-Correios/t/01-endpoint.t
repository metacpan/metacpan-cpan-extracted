use strict;
use warnings;
use Test2::V0;

plan 5;

use Net::Correios;

like dies { Net::Correios->new() },
     qr/"username" and "password" are required/,
     'new() dies without args';

like dies { Net::Correios->new( username => 'foo' ) },
     qr/"username" and "password" are required/,
     'new() dies with only the token/username';

like dies { Net::Correios->new( password => 'foo' ) },
     qr/"username" and "password" are required/,
     'new() dies with only the password/key';

my $api = Net::Correios->new( username => 'foo', password => 'bar' );
ok !$api->is_sandbox, 'production environment';
$api = Net::Correios->new( sandbox => 1, username => 'foo', password => 'bar' );
ok $api->is_sandbox, 'sandbox environment';


done_testing;
