#!perl

use strict;
use warnings;

use Test::More;
use Test::Moose;

BEGIN {
    use_ok('PONAPI::Client::Request::Retrieve');
}

my %TEST_DATA = (
    type    => 'articles',
    id      => 2,
    fields  => { articles => [qw< title body >] },
    include => [qw< comments author >],
);

subtest '... testing object' => sub {

    my $req = PONAPI::Client::Request::Retrieve->new( %TEST_DATA );

    isa_ok( $req, 'PONAPI::Client::Request::Retrieve');
    does_ok($req, 'PONAPI::Client::Request');
    does_ok($req, 'PONAPI::Client::Request::Role::IsGET');
    does_ok($req, 'PONAPI::Client::Request::Role::HasType');
    does_ok($req, 'PONAPI::Client::Request::Role::HasId');
    does_ok($req, 'PONAPI::Client::Request::Role::HasFields');
    does_ok($req, 'PONAPI::Client::Request::Role::HasFilter');
    does_ok($req, 'PONAPI::Client::Request::Role::HasInclude');
    does_ok($req, 'PONAPI::Client::Request::Role::HasPage');

    can_ok( $req, 'request_params' );

};

subtest '... testing request parameters' => sub {

    my $req = PONAPI::Client::Request::Retrieve->new( %TEST_DATA );

    my $EXPECTED = +{
        method       => 'GET',
        path         => '/articles/2',
        query_string => 'fields%5Barticles%5D=title%2Cbody&include=comments%2Cauthor',
    };

    my $GOT = +{ $req->request_params };

    is_deeply( $GOT, $EXPECTED, 'checked request parametes' );

};

subtest '... testing request path base' => sub {

    my $req = PONAPI::Client::Request::Retrieve->new(
        %TEST_DATA,
        uri_base => '/myAPI/v3/',
    );

    my $EXPECTED = +{
        method       => 'GET',
        path         => '/myAPI/v3/articles/2',
        query_string => 'fields%5Barticles%5D=title%2Cbody&include=comments%2Cauthor',
    };

    my $GOT = +{ $req->request_params };

    is_deeply( $GOT, $EXPECTED, 'checked request parametes' );

};

subtest '... testing request path templating' => sub {
    foreach my $template (
        '/a/test/of/uri/template/path/with/id/{id}/and/type/{type}',
        '{}/a//path/with/id/{id}/and/type/{type}',
        "_woah_what_is_{type}_key_{id}_doing_here_",
        "-{type}-{id}-"
    )
    {
        my $req = PONAPI::Client::Request::Retrieve->new(
            %TEST_DATA,
            uri_template => $template,
        );

        (my $expected_path = $template) =~ s/
            \{
                ( [^}]+ )
            \}
        /
            my $meth = $1;
            eval { $req->$meth } || ""
        /egx;
        my $EXPECTED = {
            method => 'GET',
            path => $expected_path,
            query_string =>
              'fields%5Barticles%5D=title%2Cbody&include=comments%2Cauthor',
        };

        my $GOT = +{ $req->request_params };
        is_deeply( $GOT, $EXPECTED, 'checked request parametes' );
    }
};

done_testing;
