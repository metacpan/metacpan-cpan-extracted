use FindBin qw($Bin);

use lib "$Bin/../lib";
use lib "$Bin/lib";

use Test::More;
use Test::Deep;

use qbit;

use TestWebInterface;

my $wi = new_ok('TestWebInterface');

cmp_deeply(
    $wi->get_cmds(),
    {
        test => {
            cmd1 => {
                type    => 'CMD',
                package => 'TestWebInterface::Controller::Test',
                attrs   => {},
                sub     => ignore,
            },
            formcmd1 => {
                type           => 'FORM',
                package        => 'TestWebInterface::Controller::Test',
                attrs          => {},
                sub            => ignore,
                process_method => '_process_form',
            },
        },
    },
    'Checking CMDs'
);

my $response = $wi->get_response(test => cmd1 => {});

like(${$response->data}, qr/Test text: Q-Bit/,            'Checking template variable text');
like(${$response->data}, qr/<!DOCTYPE html><html><head>/, 'Checking spaces trim');

$response = $wi->get_response(test => formcmd1 => {});
like(
    ${$response->data},
qr/^<!DOCTYPE html><html><head>.+?<form .+?method="post">.+?<legend>Test form 1<\/legend><input type="hidden" name="save" value=".+?" \/>.+?<input type="" class="span9" name="testinput" value="i1" \/>.+?<button .+? type="submit">Submit<\/button>.+?<\/form>/,
    'Checking generate form'
);

done_testing();
