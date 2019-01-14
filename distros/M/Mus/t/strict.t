use strictures 2;

use Test::Exception tests => 2;

use Mus;

ro "test";

lives_ok { main->new(test => "successful") } 'created successfully';

throws_ok { main->new(test => "failure", i_dont_exist => '-i') } qr//, 'Unkown attribute fails constrcutor';
