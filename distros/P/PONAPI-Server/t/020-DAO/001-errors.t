#!perl
use strict;
use warnings;

use Data::Dumper;
use Test::More;
use JSON::MaybeXS;

use PONAPI::DAO;
use Test::PONAPI::Repository::MockDB;
use Test::PONAPI::Repository::MockDB::Loader;

my $repository = Test::PONAPI::Repository::MockDB->new;
my $dao = PONAPI::DAO->new( version => '1.0', repository => $repository );


my @TEST_ARGS_TYPE     = ( type => 'articles' );
my @TEST_ARGS_TYPE_ID  = ( type => 'articles', id => 1 );

my $ERR_ID_MISSING          = "`id` is missing for this request";
my $ERR_ID_NOT_ALLOWED      = "`id` is not allowed for this request";
my $ERR_DATA_MISSING        = "request body is missing `data`";
my $ERR_BODY_NOT_ALLOWED    = "request body is not allowed";
my $ERR_RELTYPE_MISSING     = "`relationship type` is missing for this request";
my $ERR_RELTYPE_NOT_ALLOWED = "`relationship type` is not allowed for this request";
my $ERR_PAGE_NOT_ALLOWED    = "`page` is not allowed for this request";

my $SERVER_ERROR_DETAIL = 'A fatal error has occured, please check server logs';
my $SERVER_ERROR = [ 500, [], {
    errors => [{
        detail => $SERVER_ERROR_DETAIL,
        status => 500
    }],
    jsonapi => { version => '1.0' }
}];

{
    package Horrible::Object::Overloads::To::False;
    use overload
        bool => sub {''},
        fallback => 1;
    sub new { bless {}, __PACKAGE__ }
}

sub error_test {
    my ($ret, $expect, $desc) = @_;
    my ($status, $headers, $doc) = @$ret;

    my $errors = $doc->{errors};
    is( ref $errors, 'ARRAY', '... `errors` is an array-ref' );
    is_deeply($headers, [], "... no location headers since it was an error");

    my $expect_is_re = ref($expect->{detail}) eq ref(qr//);

    my ($err) = grep {
        $expect_is_re
            ? $_->{detail} =~ $expect->{detail}
            : $_->{detail} eq $expect->{detail}
    } @$errors;
    if ( !$err ) {
        fail("Didn't get an error, failing") for 1..2;
        my $line = (caller(0))[2];
        diag(Dumper({"error_test called at line $line, response was " =>  $ret}, expect => $expect));
        return;
    }
    my $test = $expect_is_re ? \&like : \&is;
    $test->( $err->{detail}, $expect->{detail}, $desc );

    my $statuses = $expect->{status};
    $statuses = [ $statuses ] if !ref $statuses;
    my ($matching) = grep $err->{status} == $_, @$statuses;
    ok($matching, '... and it has the expected error code' )
        or diag("Error has status $err->{status}, we were looking for @{$statuses}");
}

subtest '... retrieve all' => sub {

    {
        my @ret = $dao->retrieve_all();
        error_test(
            \@ret,
            {
                detail => "Bad request data: Parameter `type` is required",
                status => 400,
            },
            "type is required"
        );
    }

    foreach my $tuple (
        [
            [ @TEST_ARGS_TYPE_ID ],
            $ERR_ID_NOT_ALLOWED,
            "id is not allowed"
        ],
        [
            [ @TEST_ARGS_TYPE, data => { id => 1 } ],
            $ERR_BODY_NOT_ALLOWED,
            "body is not allowed"
        ],
        [
            [ @TEST_ARGS_TYPE, include => [qw/author/] ],
            "Types `articles` and `author` are not related",
            "include with unknown types are caught",
            404
        ],
      )
    {
        my ( $args, $expected_detail, $desc, $expected_status) = @$tuple;
        my @ret = $dao->retrieve_all(@$args);
        error_test(
            \@ret,
            { detail => $expected_detail, status => $expected_status||400 },
            "..."
        );
    }
};

subtest '... retrieve' => sub {

    {
        my @ret = $dao->retrieve();
        error_test(
            \@ret,
            {
                detail => "Bad request data: Parameter `type` is required",
                status => 400,
            },
            "Parameter `type` is required"
        );
    }

    foreach my $tuple (
        [
            [ @TEST_ARGS_TYPE ],
            $ERR_ID_MISSING,
            "id is required (missing)"
        ],
        [
            [ @TEST_ARGS_TYPE_ID, data => { id => 1 } ],
            $ERR_BODY_NOT_ALLOWED,
            "body is not allowed"
        ],
      )
    {
        my ( $args, $expected_detail, $desc ) = @$tuple;
        my @ret = $dao->retrieve(@$args);
        error_test(
            \@ret,
            { detail => $expected_detail, status => 400 },
            "errors come back as 400s + empty extra headers"
        );
    }


    # Retrieve with nonexistent stuff
    foreach my $tuple (
        [
            { include => [qw/nope/],          },
            { detail => "Types `people` and `nope` are not related", status => 404, },
        ],
        [
            { fields => { nope => ['nope'] },   },
            { detail => "Type `nope` doesn\'t exist.", status => 404, },
        ],
        [
            { fields => { people => ['nope'] }, },
            { detail => "Type `people` does not have at least one of the requested fields", status => 400, },
        ],
    )
    {
        my ($args, $expect) = @$tuple;
        my @ret = $dao->retrieve( @TEST_ARGS_TYPE, type => 'people', id => 42, %$args );
        error_test(
            \@ret,
            $expect,
            "... caught bad retrieve with ", encode_json($args),
        );
    }

};

subtest '... retrieve relationships' => sub {

    foreach my $tuple (
        [
            [ @TEST_ARGS_TYPE ],
            $ERR_ID_MISSING,
            "id is required (missing)"
        ],
        [
            [ @TEST_ARGS_TYPE_ID ],
            $ERR_RELTYPE_MISSING,
            "rel_type is missing"
        ],
        [
            [
                @TEST_ARGS_TYPE_ID,
                rel_type => "comments",
                data     => { id => 1 }
            ],
            $ERR_BODY_NOT_ALLOWED,
            "body is not allowed"
        ],
      )
    {
        my ( $args, $expected_detail, $desc, $expected_status ) = @$tuple;
        foreach my $method (qw/retrieve_by_relationship retrieve_relationships/) {
            my @ret = $dao->$method(@$args);
            error_test(
                \@ret,
                { detail => $expected_detail, status => $expected_status||400 },
                "$desc $method"
            );
        }
    }

};

subtest '... create' => sub {

    {
        my @res = $dao->create(
            @TEST_ARGS_TYPE,
            data => {},
        );
        my $expected = [
            400,
            [],
            {
                errors  => [
                    {
                        detail => 'request data has no `type` key',
                        status => 400
                    }
                ],
                jsonapi => { version => '1.0' }
            }
        ];
        is_deeply( \@res, $expected, 'create missing type in data' );
    }

    {
        my @res = $dao->create(
            @TEST_ARGS_TYPE,
            data => { type => "not_articles" },
        );
        my $expected = [
            409,
            [],
            {
                errors  => [
                    {
                        detail => 'conflict between the request type and the data type',
                        status => 409,
                    }
                ],
                jsonapi => { version => '1.0' }
            }
        ];
        is_deeply( \@res, $expected, 'create types conflict' );
    }

    foreach my $tuple (
        [
            [ @TEST_ARGS_TYPE_ID ],
            $ERR_ID_NOT_ALLOWED,
            "id is not allowed"
        ],
        [
            [ @TEST_ARGS_TYPE, rel_type => 1 ],
            $ERR_RELTYPE_NOT_ALLOWED,
            "bad rel_type"
        ],
        [
            [ @TEST_ARGS_TYPE, rel_type => 'authors' ],
            $ERR_RELTYPE_NOT_ALLOWED,
            "rel_type is not allowed"
        ],
        [
            [ @TEST_ARGS_TYPE ],
            $ERR_DATA_MISSING,
            "data is missing"
        ],

        # Spec says these two need to return 409
        [
            [ @TEST_ARGS_TYPE, data => { type => "" } ],
            "conflict between the request type and the data type",
            "data->{type} is missing",
            409
        ],
        [
            [ @TEST_ARGS_TYPE, data => { type => "fake" } ],
            "conflict between the request type and the data type",
            "data->{type} is wrong",
            409
        ],
      )
    {
        my ( $args, $expected_detail, $desc, $expected_status ) = @$tuple;
        my @ret = $dao->create(@$args);
        error_test(
            \@ret,
            { detail => $expected_detail, status => $expected_status || 400 },
            $desc,
        );
    }

    foreach my $tuple (
        [
            { data => { attributes => {} } },
            # 409 + SQL Error: Table constraint failed: $etc,
            # or, if we have an old SQLite,
            # 400 + SQL Error: $etc
            # The DBD is there just in case.  It should still
            # gives us a 400 in that case.
            [400, 409] => qr/(?:\ASQL error:|DBD)/,
            "... error on bad create values"
        ],
        [
            {
                data => {
                    attributes => {
                        title => "Title!",
                        body  => "Body!",
                        extra => 111
                    }
                }
            },
            400 => 'Type `articles` does not have at least one of the attributes in data',
            "... error on unknown attributes"
        ],
        [
            {
                data => {
                    relationships => {
                        authors => [
                            { type => people => id => 42 },
                            { type => people => id => 43 },
                        ]
                    }
                }
            },
            400 => 'Types `articles` and `authors` are one-to-one, but got multiple values',
            "... error on unknown relationships"
        ],
        [
            {
                data => {
                    relationships => {
                        nope => { type => people => id => 42 }
                    }
                }
            },
            404 => 'Types `articles` and `nope` are not related',
            "... error on unknown relationships"
        ],
        [
            {
                data => {
                    relationships =>
                      { authors => { type => comments => id => 5 } }
                }
            },
            400 => 'Bad request data: Data has type `comments`, but we were expecting `people`',
            "... error on relationship conflicts"
        ],
      )
    {
        my $copy = {
            @TEST_ARGS_TYPE,
            data     => {
                type => "articles",
                attributes => {
                    title => "Title!",
                    body  => "Body!",
                },
                relationships => {
                    authors => { type => 'people', id => 42 },
                },
            },
        };
        my ( $body, $status, $expected, $msg ) = @$tuple;

        while ( my ( $k, $v ) = each %$body ) {
            if ( ref($v) ) {
                while ( my ( $k2, $v2 ) = each %$v ) {
                    $copy->{$k}{$k2} = $v2;
                }
            }
            else {
                $copy->{$k} = $v;
            }
        }

        my ( $w, @ret ) = ('');
        {
            local $SIG{__WARN__} = sub { $w .= shift };
            @ret = $dao->create(%$copy);
        }
        error_test(
            \@ret,
            { detail => $expected, status => $status },
            "... $msg",
        );
        if ( ref($expected) ) {
            like( $w, $expected, "... and the warning matches" );
        }
        else {
            is( $w, '', "... with no warnings" );
        }
    }

};

subtest '... update' => sub {

    # Update with a bad/missing id
    foreach my $id ( -99, 99, "bad" ) {
        my @ret = $dao->update(
            @TEST_ARGS_TYPE,
            id => $id,
            data => {
                type => 'articles',
                id   => $id,
                attributes => { title => "Nonexistent" },
            },
        );
        my $expected = [
            404,
            [],
            {
                jsonapi => { version => '1.0' },
                meta    => { detail  => '' },
            }
        ];
        $ret[2]->{meta}{detail} = '';
        is_deeply(
            \@ret,
            $expected,
            "trying to update a non-existent attribute should give a 404 and a body explaining why"
        );
    }

    # Updating nonexistent attributes
    {
        my @ret = $dao->update(
            @TEST_ARGS_TYPE_ID,
            data => {
                @TEST_ARGS_TYPE_ID,
                attributes => { not_real_attr => "not there!" },
            },
        );
        is_deeply(
            \@ret,
            [
                400,
                [],
                {
                    errors => [
                        {
                            detail => 'Type `articles` does not have at least one of the attributes in data',
                            status => 400
                        }
                    ],
                    jsonapi => { version => '1.0' }
                }
            ],
            "... 400 + error when updating an unknown attribute",
        );
    }

    # Updating nonexistent relationships
    {
        my @ret = $dao->update(
            @TEST_ARGS_TYPE_ID,
            data => {
                @TEST_ARGS_TYPE_ID,
                relationships => { not_real_rel => { type => fake => id => 1 } },
            },
        );
        is_deeply(
            \@ret,
            [
                404,
                [],
                {
                    errors => [
                        {
                            detail => 'Types `articles` and `not_real_rel` are not related',
                            status => 404
                        }
                    ],
                    jsonapi => { version => '1.0' }
                }
            ],
            "... 404 + error when updating an unknown relationship"
        );
    }

    # Update with a bad relationship; should roll back (imp. dependent)
    my @first_retrieve = $dao->retrieve( @TEST_ARGS_TYPE_ID );
    my ( $w, @ret ) = ('');
    {
        local $SIG{__WARN__} = sub { $w .= shift };
        @ret = $dao->update(
            @TEST_ARGS_TYPE_ID,
            data => {
                @TEST_ARGS_TYPE_ID,
                attributes    => { title => "All good" },
                relationships => {
                    comments => [
                        # These two are comments of article 2
                        { type => comments => id => 5  },
                        { type => comments => id => 12 },
                    ],
                },
            },
        );
    }
    my @second_retrieve = $dao->retrieve( @TEST_ARGS_TYPE_ID );
    is_deeply(
        \@first_retrieve,
        \@second_retrieve,
        "... changes are rolled back"
    );
    is( $ret[0], 409, "... the update had the correct error status" );
    ok( exists $ret[2]->{errors}, "... and an errors member" );
    ok( $w,                       "... and we gave a perl warning, too" );

};

subtest '... delete' => sub {

    foreach my $tuple (
        [
            [ @TEST_ARGS_TYPE ],
            $ERR_ID_MISSING,
            "id is missing"
        ],
        [
            [ @TEST_ARGS_TYPE_ID, rel_type => 1 ],
            $ERR_RELTYPE_NOT_ALLOWED,
            "rel_type is not allowed",
        ],
        [
            [ @TEST_ARGS_TYPE_ID, rel_type => 0 ],
            $ERR_RELTYPE_NOT_ALLOWED,
            "rel_type is not allowed (false rel_type value)",
        ],
        [
            [ @TEST_ARGS_TYPE_ID, rel_type => "" ],
            $ERR_RELTYPE_NOT_ALLOWED,
            'rel_type is not allowed (not allowed rel_type "")',
        ],
        [
            [ @TEST_ARGS_TYPE_ID, rel_type => "comments" ],
            $ERR_RELTYPE_NOT_ALLOWED,
            "rel_type is not allowed",
        ],
        [
            [ @TEST_ARGS_TYPE_ID, data => { type => "" } ],
            $ERR_BODY_NOT_ALLOWED,
            "data is not allowed"
        ],
      )
    {
        my ( $args, $expected, $desc, $status ) = @$tuple;
        my @ret = $dao->delete(@$args);
        error_test(
            \@ret,
            { detail => $expected, status => $status||400 },
            "... $desc",
        );
    }

};

subtest '... create_relationships' => sub {

    foreach my $tuple (
        [
            [ @TEST_ARGS_TYPE ],
            $ERR_ID_MISSING,
            "... id is missing"
        ],
        [
            [ @TEST_ARGS_TYPE_ID, rel_type => 'comments' ],
            $ERR_DATA_MISSING,
            "... data is missing",
        ],
        [
            [ @TEST_ARGS_TYPE_ID, data => [] ],
            $ERR_RELTYPE_MISSING,
            "... rel_type is missing"
        ],
        [
            [ @TEST_ARGS_TYPE_ID, rel_type => 'authors', data => [{}] ],
            "Types `articles` and `authors` are one-to-one",
            "... bad relationship",
        ],
      )
    {
        my ( $args, $expected_detail, $desc, $expected_status ) = @$tuple;
        my @ret = $dao->create_relationships(@$args);
        error_test(
            \@ret,
            { detail => $expected_detail, status => $expected_status||400 },
            "$desc create_relationships"
        );
    }

    # A conflict should return a 409
    # Also testing the rollback here, which is entirely implementation
    # dependent, but mandated by the spec
    my @first_retrieve = $dao->retrieve( @TEST_ARGS_TYPE_ID );
    my $w   = '';
    my @ret = do {
        local $SIG{__WARN__} = sub { $w .= shift };
        $dao->create_relationships(
            @TEST_ARGS_TYPE_ID,
            rel_type => 'comments',
            data     => [
                { type => comments => id => 99 },

                # Second one belongs to article 2
                { type => comments => id => 12 },
            ],
        );
    };

    error_test(
        \@ret,
        { detail => qr/SQL error/, status => [400, 409] },
        "... no DBD error in detail as expected",
    );

    my @second_retrieve = $dao->retrieve( @TEST_ARGS_TYPE_ID );
    is_deeply(
        \@first_retrieve,
        \@second_retrieve,
        "... and the changes are not applied"
    );

    @ret = $dao->create_relationships(
        @TEST_ARGS_TYPE_ID,
        rel_type => 'comments',
        data     => [ { type => fake => id => 99 }, ],
    );

    error_test(
        \@ret,
        { detail => 'Bad request data: Data has type `fake`, but we were expecting `comments`', status => 400 },
        "... discrepancies between the requested rel_type and the data are spotted",
    );

    @ret = $dao->create_relationships(
        @TEST_ARGS_TYPE_ID,
        rel_type => 'comments',
        data => { type => comments => id => 3333 }, # Hashref, not an arrayref
    );

    error_test(
        \@ret,
        {
            detail => 'Bad request data: Parameter `data` expected Collection[Resource], but got a {"id":3333,"type":"comments"}',
            status => 400,
        },
        "... create relationships MUST pass an arrayref of hashrefs"
    );

};

subtest '... delete_relationships' => sub {

    {
        # Trying to delete a non-existent relationship
        # should return a 204:
        # http://jsonapi.org/format/#crud-updating-relationship-responses-204
        my @ret = $dao->delete_relationships(
            @TEST_ARGS_TYPE_ID,
            req_path => '/articles/1/comments',
            rel_type => 'comments',
            data     => [ { type => comments => id => 99 }, ],
        );

        is_deeply(
            \@ret,
            [
                204,
                [],
            ],
            "... deleting a non-existent resource returns a 204"
        );
    }

    {
        # Trying to delete a one-to-one is invalid
        my @ret = $dao->delete_relationships(
            @TEST_ARGS_TYPE_ID,
            rel_type => 'authors',
            data     => [ { type => people => id => 42 }, ],
        );

        error_test(
            \@ret,
            { detail => 'Types `articles` and `authors` are one-to-one', status => 400 },
            "... can't delete_relationships on a one-to-one",
        );
    }

};

subtest '... illegal params' => sub {

    # Bad params for request.
    my %all_args = (
        id       => { expected_detail => $ERR_ID_NOT_ALLOWED,      id => 1 },
        rel_type => { expected_detail => $ERR_RELTYPE_NOT_ALLOWED, rel_type => 'comments' },
        data     => { expected_detail => $ERR_BODY_NOT_ALLOWED,    data => { type => articles => id => 1 } },
        page     => { expected_detail => $ERR_PAGE_NOT_ALLOWED,    page => {} },
        fields   => { fields => { articles => [qw/title/] } },
        include  => { include => [ qw/comments/ ] },
        sort     => { sort => [] },
    );

    my %request = (
        retrieve_all => {
            args    => \@TEST_ARGS_TYPE,
            allowed => [qw/ page include fields sort /],
        },
        retrieve     => {
            args    => \@TEST_ARGS_TYPE_ID,
            allowed => [qw/ page include fields id sort /],
        },
        retrieve_relationships => {
            args    => [@TEST_ARGS_TYPE_ID, rel_type => 'authors'],
            allowed => [qw/ page id rel_type sort /],
        },
        retrieve_by_relationship => {
            args    => [@TEST_ARGS_TYPE_ID, rel_type => 'authors'],
            allowed => [qw/ page include fields id rel_type sort /],
        },

        create => {
            args    => [ @TEST_ARGS_TYPE, data => {
                @TEST_ARGS_TYPE, attributes => { title => "woah" },
            } ],
            allowed => [qw/ id data /],
        },

        delete => {
            args    => \@TEST_ARGS_TYPE_ID,
            allowed => [qw/ id /],
        },

        update => {
            args    => [ @TEST_ARGS_TYPE_ID, data => { @TEST_ARGS_TYPE_ID, attributes => { title => "foobar" } } ],
            allowed => [qw/ id data /],
        },
        update_relationships => {
            args    => [@TEST_ARGS_TYPE_ID, rel_type => 'comments', data => [{ type => 'comments', id => 5555 }]],
            allowed => [qw/ id rel_type data /],
        },
        delete_relationships => {
            args    => [@TEST_ARGS_TYPE_ID, rel_type => 'comments', data => [{ type => 'comments', id => 5555 }]],
            allowed => [qw/ id rel_type data /],
        },
        create_relationships => {
            args    => [@TEST_ARGS_TYPE_ID, rel_type => 'comments', data => [{ type => 'comments', id => 5555 }]],
            allowed => [qw/ id rel_type data /],
        },
    );

    foreach my $action ( sort keys %request ) {
        my ($args, $allowed) = @{ $request{$action} }{qw/args allowed/};
        my %allowed = map +($_=>1), @$allowed;

        my $glob = do {
            no strict 'refs';
            \*{"Test::PONAPI::Repository::MockDB::${action}"};
        };

        {
            use PONAPI::Constants;
            no warnings 'redefine';
            local *$glob = sub {
                my ($self, %args) = @_;
                $args{document}->add_resource( type => 'comments', id => 1 );
                return PONAPI_UPDATED_NORMAL;
            };
            use warnings;

            my @base_ret = $dao->$action(@$args);
            cmp_ok($base_ret[0], '<', 300, "... without any changes, we get a successful $action");

            # Check that disallowed arguments give us graceful errors
            my @disallowed = grep !exists $allowed{$_}, sort keys %all_args;
            foreach my $disallowed_arg ( @disallowed ) {
                my $expected_detail = $all_args{$disallowed_arg}{expected_detail};
                my @ret = $dao->$action(@$args,
                    %{ $all_args{$disallowed_arg} },
                );
                error_test(
                    \@ret,
                    {
                        detail => $expected_detail || "`$disallowed_arg` is not allowed for this request",
                        status => 400,
                    },
                    "... catches $disallowed_arg being passed to $action",
                );
            }

            my $overloads_to_false = Horrible::Object::Overloads::To::False->new;
            foreach my $error (
                'Server error, halp at',
                $overloads_to_false,
            )
            {
                my $w   = '';
                my @ret = do {
                    no warnings 'redefine';
                    local $SIG{__WARN__} = sub { $w .= shift };
                    local *$glob = sub { die $error };
                    $dao->$action(@$args);
                };
                is_deeply(
                    \@ret,
                    $SERVER_ERROR,
                    "... expected PONAPI response for error on $action"
                );
                my $expected_re = $error
                                ? qr/\A\Q$error\E/
                                : qr/\AUnknown error/;
                like(
                    $w,
                    $expected_re,
                    "... expected perl error from $action"
                );
            }

            # See that we catch people using PONAPI::Exception without
            # an exception type
            my ($w, @ret) = ('');
            my $msg = "my great exception!";
            @ret = do {
                no warnings 'redefine';
                local $SIG{__WARN__} = sub { $w .= shift };
                local *$glob = sub {
                    PONAPI::Exception->throw(message => $msg)
                };
                $dao->$action(@$args);
            };
            is_deeply(
                \@ret,
                $SERVER_ERROR,
                "... we catch exceptions without types",
            );
            like($w, qr/\A\Q$msg\E/, "... and make them warn");

            # Let's also test that all the methods detect unknown types
            $w = '';
            my %modified_arguments = @$args;
            $modified_arguments{type} = 'fake';
            my $data = $modified_arguments{data} || [];
            $data = [ $data ] if ref($data) ne 'ARRAY';
            {
                local $_->{type} = 'fake' for @$data;
                @ret = $dao->$action( %modified_arguments );
            }
            error_test(
                \@ret,
                {
                    detail => 'Type `fake` doesn\'t exist.',
                    status => 404,
                },
                "... bad types in $action lead to a 404",
            );
            is( $w, '', "... and no warnings" );

            # Check that update-like operations have strict return values
            my %strict_return_values = map +($_=>1), qw/
                update create_relationships
                update_relationships delete_relationships
            /;
            next unless $strict_return_values{$action};
            ($w, @ret) = ('');
            {
                no warnings 'redefine';
                local $SIG{__WARN__} = sub { $w .= shift    };
                local *$glob         = sub { return -1111.5 };
                @ret = $dao->$action(@$args);
            }
            is_deeply(
                \@ret,
                $SERVER_ERROR,
                "... Bad ->$action implementations are detected"
            );
            like(
                $w,
                qr/\Qoperation returned an unexpected value\E/,
                "... and gives a normal warning, too"
            );

            # Test that we catch execute dying
            {
                my $execute_glob = do {
                    no strict 'refs';
                    \*{"PONAPI::DAO::Request::BUILD"};
                };
                my ($w, @ret) = ('');
                {
                    no warnings 'redefine';
                    local *$execute_glob = sub { die $overloads_to_false };
                    local $SIG{__WARN__} = sub { $w .= shift    };
                    @ret = $dao->$action(@$args);
                }
                is_deeply(
                    \@ret,
                    $SERVER_ERROR,
                    "... server error when the action dies",
                );
                like($w, qr/\AUnknown error/, "... and the unknown error due to the false overload");
            }

        }
    }

};

done_testing;
