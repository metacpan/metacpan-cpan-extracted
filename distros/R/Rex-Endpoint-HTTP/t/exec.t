use Mojo::Base -strict;

use Test::More tests => 3;
use Test::Mojo;

my $t = Test::Mojo->new("Rex::Endpoint::HTTP");
$t->post_json_ok("/execute" => { exec => "echo 'hi'" })->status_is(200)->json_is("/output" => "hi\n");
