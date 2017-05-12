#!perl
use strict;
use warnings;

use Test::More;
use Plack::Test;

use HTTP::Request::Common;
use JSON::MaybeXS;

BEGIN {
    use_ok('PONAPI::Server');
}

my $BAD_REQUEST_MSG = "{JSON:API} Bad request";
my $NO_MATCH_MSG    = "{JSON:API} No matching route";

my %CT     = ( 'Content-Type' => 'application/vnd.api+json' );
my %Accept = ( 'Accept'       => 'application/vnd.api+json' );

sub error_test {
    my ($res, $expected, $desc) = @_;

    my $h = $res->headers;
    is( $h->header('Content-Type')||'', 'application/vnd.api+json', "... has the right content-type" );
    is( $h->header('X-PONAPI-Server-Version')||'', '1.0', "... and gives us the custom X-PONAPI-Server-Version header" );
    is( $h->header('Location')||'', '', "... no location headers since it was an error");

    cmp_ok( $res->code, '>=', 400, "... response is an error" );

    my $content = decode_json $res->content;
    my $errors = $content->{errors};
    is( ref $errors, 'ARRAY', '... `errors` is an array-ref' );

    my ($err) = grep { $_->{detail} eq $expected->{detail} } @{ $errors };
    is( $err->{detail}, $expected->{detail}, $desc ) or diag("Test failed: $desc");
    is( $err->{status},  $expected->{status}, '... and it has the expected error code' );
}

### ...

my $app = Plack::Test->create( PONAPI::Server->new()->to_app );

subtest '... include errors' => sub {

    {
        my $res = $app->request( GET '/articles/2?include=comments', %Accept );
        is( $res->code, 200, 'existing relationships are OK' );
    }

    {
        my $res = $app->request( GET '/articles/1/relationships/0', %Accept );
        error_test(
            $res,
            {
                detail => "Types `articles` and `0` are not related",
                status => 404,
            }
        );
    }

    {
        my $res = $app->request( GET '/articles/1/relationships//', %Accept );
        is($res->code, 400, "... error empty-string relationship");
        is(
            (decode_json($res->content)||{})->{errors}[0]{detail},
            $BAD_REQUEST_MSG,
            "empty-string relationships are not allowed"
        );
    }

    {
        my $res = $app->request( GET '/articles/2?include=asdasd,comments.not_there', %Accept );
        # expecting 400 becuase we have multiple 4xx errors
        is( $res->code, 400, 'non-existing relationships are not found' );
    }

    {
        my $res = $app->request( GET '/articles/1?fields[articles]=nope', %Accept );
        error_test(
            $res,
            {
                detail => 'Type `articles` does not have at least one of the requested fields',
                status => 400,
            },
            "... bad fields are detected",
        );
    }

    {
        # Note the nope
        my $res = $app->request( GET '/articles/1?include=nope', %Accept );
        error_test(
            $res,
            {
                detail => 'Types `articles` and `nope` are not related',
                status => 404,
            },
            "... bad includes are detected",
        );


        $res = $app->request( GET '/articles/1?include=authors&fields[NOPE]=nope', %Accept );
        error_test(
            $res,
            {
                detail => 'Type `NOPE` doesn\'t exist.',
                status => 404,
            },
            "... bad field types are detected",
        );

        # Note the 'nope'
        $res = $app->request( GET '/articles/1?include=authors&fields[people]=nope', %Accept );
        error_test(
            $res,
            {
                detail => 'Type `people` does not have at least one of the requested fields',
                status => 400,
            },
            "... bad fields are detected",
        );
    }

};

subtest '... bad requests (GET)' => sub {

    {
        my $res = $app->request( GET "/_articles", %Accept );
        error_test(
            $res,
            {
                detail => $BAD_REQUEST_MSG,
                status => 400,
            },
            "... bad fields are detected",
        );
    }

    # Incomplete requests
    foreach my $req (
            'fields',
            'fields=',
            'include',
            'include=&',
            'include=',
            'include[articles]',
            'page=page',
            'filter=filter',
    ) {
        my $res = $app->request( GET "/articles/1?$req", %Accept );
        error_test(
            $res,
            {
                detail => $BAD_REQUEST_MSG,
                status => 400,
            },
            "... bad request $req caught",
        );
    }
};

subtest '... bad requests (POST)' => sub {

    {
        my $res = $app->request( POST "/articles", %CT );
        error_test(
            $res,
            {
                detail => '{JSON:API} No {json:api} Media-Type (Content-Type / Accept)',
                status => 415,
            },
            "... POST with no body (wo/Accept header)",
        );
    }

    {
        my $res = $app->request( POST "/articles", %CT, %Accept );
        error_test(
            $res,
            {
                detail => 'request body is missing `data`',
                status => 400,
            },
            "... POST with no body (w/Accept header)",
        );
    }

    {
        my $res = $app->request( POST "/articles", %CT, Content => "hello" );
        error_test(
            $res,
            {
                detail => $BAD_REQUEST_MSG,
                status => 400,
            },
            "... POST with non-JSON body",
        );
    }

    {
        my $res = $app->request( POST "/articles/relationships/", %CT, Content => { 'x' => 'y' } );
        error_test(
            $res,
            {
                detail => $NO_MATCH_MSG,
                status => 404,
            },
            "... POST with relationships without rel_type",
        );
    }

    {
        my $create_rel = $app->request(
            POST '/articles/2/relationships/authors', %CT,
            Content => encode_json({ data => { id => 5, type => 'people'} }),
        );
        error_test(
            $create_rel,
            {
                detail => 'Bad request data: Parameter `data` expected Collection[Resource], but got a {"id":5,"type":"people"}',
                status => 400,
            },
            "retrieve by relationships"
        )
    }

    # data is not hash-ref/array-ref/undef.
    {
        my $create = $app->request(
            POST '/comments', %CT,
            Content => encode_json({ data => 1 }),
        );
        error_test(
            $create,
            {
                detail => '{JSON:API} Bad request',
                status => 400,
            },
            "data => 1"
        )
    }

    # invalid name for `type`
    {
        my $create = $app->request(
            POST '/comments-', %CT,
            Content => encode_json({ data => { type => 'comments-', attributes => { "title" => "XXX" } } }),
        );
        error_test(
            $create,
            {
                detail => '{JSON:API} Bad request (invalid member-name)',
                status => 400,
            },
            "invalid type names"
        )
    }

    # `data.relationships` is not a hash
    {
        my $create = $app->request(
            POST '/comments', %CT,
            Content => encode_json({ data => { type => 'comments', attributes => { "title" => "XXX" }, relationships => 1 } }),
        );
        error_test(
            $create,
            {
                detail => '{JSON:API} Bad request',
                status => 400,
            }
        )
    }

    # invalid name for `data.relationships` key
    {
        my $create = $app->request(
            POST '/comments', %CT,
            Content => encode_json({ data => { type => 'comments', relationships => { "<invalid>" =>  { data => { type => 'articles', id => 1 } } } } }),
        );
        error_test(
            $create,
            {
                detail => '{JSON:API} Bad request (invalid member-name)',
                status => 400,
            }
        )
    }

    # invalid name for `data.relationships.type`
    {
        my $create = $app->request(
            POST '/comments', %CT,
            Content => encode_json({
                data => {
                    type => 'comments',
                    relationships => {
                        articles => {
                            data => {
                                type => 'articles-',
                                id   => 1,
                            },
                        },
                    },
                },
            }),
        );
        error_test(
            $create,
            {
                detail => '{JSON:API} Bad request (invalid member-name)',
                status => 400,
            },
            "invalid relationships"
        )
    }


    # `data.attributes` is not a hash
    {
        my $create = $app->request(
            POST '/comments', %CT,
            Content => encode_json({ data => { type => 'comments', attributes => 1 } }),
        );
        error_test(
            $create,
            {
                detail => '{JSON:API} Bad request',
                status => 400,
            }
        )
    }

    # invalid `data.attributes` key
    {
        my $create = $app->request(
            POST '/comments', %CT,
            Content => encode_json({ data => { type => 'comments', attributes => { "title" => "XXX", "<invalid>" => "1" } } }),
        );
        error_test(
            $create,
            {
                detail => '{JSON:API} Bad request (invalid member-name)',
                status => 400,
            },
            "invalid `data.attributes` key"
        )
    }

};

done_testing;
