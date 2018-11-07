use FindBin qw($Bin);

use lib "$Bin/../lib";
use lib "$Bin/lib";

use Test::More;
use Test::Deep;

use qbit;

use TestWebInterface;

my $wi = new_ok('TestWebInterface');

my $routing = $wi->routing();

$routing->post('/formcmd2/!field!')->to(
    sub {
        my ($controller, %opts) = @_;

        return $controller->as_text(sprintf('%s - field: %s', ref($controller), $opts{'field'}));
    }
)->attrs('CMD');

cmp_deeply(
    $wi->get_cmds(),
    {
        '__HANDLER_PATH_1__' => {
            '__HANDLER_CMD_1__' => {
                'sub'        => ignore(),
                'sub_name'   => '__HANDLER_CMD_1__',
                'package'    => 'QBit::WebInterface::Controller',
                'attributes' => {'CMD' => 1}
            }
        },
        'test' => {
            'cmd1' => {
                'package'    => 'TestWebInterface::Controller::Test',
                'sub'        => ignore(),
                'sub_name'   => 'cmd1',
                'attributes' => {
                    'CMD' => 1
                }
            },
            'cmd2' => {
                'sub_name'   => 'cmd2',
                'sub'        => ignore(),
                'attributes' => {
                    'URL' => 1,
                    'CMD' => 1
                },
                'route_params' => ['GET', '/cmd2/!field!'],
                'package'      => 'TestWebInterface::Controller::Test'
            },
            'formcmd1' => {
                'attributes' => {
                    'FORM' => 1
                },
                'process_method' => '_process_form',
                'sub'            => ignore(),
                'sub_name'       => 'formcmd1',
                'package'        => 'TestWebInterface::Controller::Test'
            }
        }
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

$response = $wi->get_response(cmd2 => 1);
is($response->data, to_json({field => '1'}), 'Checking attribute "URL"');

$response = $wi->get_response(formcmd2 => 2 => {}, method => 'POST');
is($response->data, 'QBit::WebInterface::Controller - field: 2', 'Checking handler route');

done_testing();
