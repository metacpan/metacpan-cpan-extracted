#!perl
use strict;
use warnings;
use Test::More;

use Pingdom::Client;

my $PC = Pingdom::Client::->new({
    'username' => 'none',
    'password' => 'none',
    'apikey'   => 'none',
});

my $ref = {
    'name' => 'Str',
    'type' => 'Checktype',
    'flag' => 'Bool',
};

ok($PC->_validate_params($ref,{
    'name' => 'A name',
    'type' => 'http',
    'flag' => 'true',
}),'True is ok');
ok($PC->_validate_params($ref,{
    'name' => 'A name',
    'type' => 'http',
    'flag' => 'false',
}),'False is ok');
ok(!$PC->_validate_params($ref,{
    'name' => 'A name',
    'type' => 'http',
    'flag' => '1',
}),'1 is not ok for true');
ok(!$PC->_validate_params($ref,{
    'name' => 'A name',
    'type' => 'http',
    'flag' => '0',
}),'0 is not ok for true');

done_testing();
