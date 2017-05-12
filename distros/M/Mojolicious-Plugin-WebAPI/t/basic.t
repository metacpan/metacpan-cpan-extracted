use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use File::Basename;
use lib dirname(__FILE__) . '/lib';

my $t = Test::Mojo->new('ApiTest');

$t->get_ok('/api/v0/')->status_is(200)->json_is(
    {
        "_links" => {
            "test_table" => {
                "href"  => "/api/v0/test_table",
                "title" => "Schema TestTable"
            },
            "test_table{/1}" => {
                "href"      => "/api/v0/test_table{/1}",
                "title"     => "Schema TestTable",
                "templated" => 1
            },
            "self" => {
                "href" => "/api/v0/"
            }
        }
    }
);

$t->get_ok('/api/v0/test_table/1')->status_is(200)->json_is(
    {
        "test_table" => [
            {
                "title"     => "test",
                "ticket_id" => 13,
                "type"      => "test_table",
                "id"        => 1,
                "href"      => "/test_table/1",
                "description" => "test description",
            }
        ],
    }
);

done_testing();
