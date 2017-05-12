use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use File::Basename;
use lib dirname(__FILE__) . '/lib';

my $t = Test::Mojo->new('ApiTest');

my $new_entry = {
    "title"       => "write test",
    "ticket_id"   => 14,
    "id"          => 2,
    "description" => "another description",
};

$t->post_ok('/api/v0/test_table?prefetch=self' => { Accept => '*/*' } => json => $new_entry )
  ->status_is(201)
  ->json_is( $new_entry );

$t->get_ok('/api/v0/test_table/2')->status_is(200)->json_is(
    {
        "test_table" => [
            {
                %{ $new_entry },
                "href" => "/test_table/2",
                "type" => "test_table",
            }
        ],
    }
);

done_testing();
