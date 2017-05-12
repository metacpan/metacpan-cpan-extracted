#!perl
use strict;
use warnings;

use JSON::MaybeXS qw[ decode_json ];

use Test::More;

BEGIN {
    use_ok('PONAPI::DAO');
    use_ok('Test::PONAPI::Repository::MockDB');
    use_ok('Test::PONAPI::Repository::MockDB::Loader');
}

my $repository = Test::PONAPI::Repository::MockDB->new;
isa_ok($repository, 'Test::PONAPI::Repository::MockDB');

ok($repository->has_type('people'),   '... we have the people type');
ok($repository->has_type('articles'), '... we have the articles type');
ok($repository->has_type('comments'), '... we have the comments type');

ok(!$repository->has_type('widgets'), '... we do not have the widgets type');

ok($repository->has_relationship(articles => 'authors'),   '... we have the expected (articles => author) relationship');
ok($repository->has_relationship(articles => 'comments'),  '... we have the expected (articles => comments) relationship');
ok($repository->has_relationship(comments => 'articles'),  '... we have the expected (comments => article) relationship');
ok($repository->has_relationship(people   => 'articles'),  '... we have the (people => articles) relationship');

ok(!$repository->has_relationship(comments => 'authors'),  '... we do not have the (comments => author) relationship (as expected)');

my $dao = PONAPI::DAO->new( version => '1.0', repository => $repository );
isa_ok($dao, 'PONAPI::DAO');

my @TEST_ARGS_TYPE    = ( type => 'articles' );
my @TEST_ARGS_TYPE_ID = ( type => 'articles', id => 2 );

subtest '... retrieve all' => sub {

    my @ret = $dao->retrieve_all( type => 'people', send_doc_self_link => 1 );
    my $doc = $ret[2];

    is(ref $doc, 'HASH', '... the document we got is a HASH ref');

    ok(exists $doc->{'jsonapi'}, '... we have a `jsonapi` key');
    ok(exists $doc->{'data'}, '... we have a `data` key');
    ok(exists $doc->{'links'}, '... we have a `links` key');
    is(scalar keys %$doc, 3, '... only got 3 keys');

    is(ref $doc->{'data'}, 'ARRAY', '... the document->{data} we got is an ARRAY ref');

    foreach my $person ( @{$doc->{'data'}} ) {
        is(ref $person, 'HASH', '... the resource we got is a HASH ref');
        is($person->{type}, 'people', '... got the expected type');

        ok(exists $person->{id}, '... the `id` key exists');
        ok(exists $person->{attributes}, '... the `attributes` key exists');

        ok(exists $person->{attributes}->{name}, '... the attribute `name` key exists');
        ok(exists $person->{attributes}->{age}, '... the attribute `age` key exists');
        ok(exists $person->{attributes}->{gender}, '... the attribute `gender` key exists');
    }

    my @include = $dao->retrieve_all(
        type => 'articles',
        send_doc_self_link => 1,
        include => [qw/comments/],
    );
    my @comment_ids = sort { $a <=> $b }
                      map $_->{id}, @{ $include[2]->{included} || [] };
    is_deeply(
        \@comment_ids,
        [5, 12],
        "...retrieve_all + include works"
    );

    my $fields = {
            articles => [qw/title authors/],
            people   => [qw/name/],
            comments => [qw/id/],
        };
    my @include_fields = $dao->retrieve_all(
        type => 'articles',
        send_doc_self_link => 1,
        include => [qw/comments authors/],
        fields  => $fields,
    );
    test_fields_response(\@include_fields, $fields);

    $fields = { articles => ["title"], comments => ["id"] };
    my @include_comments_no_body = $dao->retrieve_all(
        type => 'articles',
        send_doc_self_link => 1,
        include => [qw/comments authors/],
        fields  => $fields,
    );
    test_fields_response(\@include_comments_no_body, $fields);

    {
        # page!
        my @page = $dao->retrieve_all(
            @TEST_ARGS_TYPE,
            req_path => '/articles',
            page => {
                offset => 1,
                limit  => 1,
            },
        );
        my $doc = $page[2];
        is( scalar @{ $doc->{data}}, 1, "... we only fetched one resource, as requested" );
        is( $doc->{data}[0]{id}, 2, "... and the resource has id=2" )
            or diag("Honestly, this should break, since we are not using sort");
        my $expect = {
            first => '/articles?page%5Blimit%5D=1&page%5Boffset%5D=0',
            next  => '/articles?page%5Blimit%5D=1&page%5Boffset%5D=2',
            prev  => '/articles?page%5Blimit%5D=1&page%5Boffset%5D=0',
            self  => '/articles?page%5Blimit%5D=1&page%5Boffset%5D=1',
        };
        my $links = $doc->{links};
        is_deeply(
            $links,
            $expect,
            "... all the pagination links are there"
        );
    }

    # sort
    foreach my $sort_by (
        [qw/-id/],
        [qw/-body/],
        # Nope. Not going to implement these for MockDB, since they
        # require joins, or doing the sorts in perl
        # [qw/authors.name/],
        # [qw/body authors.name/],
    )
    {
        my @sort = $dao->retrieve_all(
            send_doc_self_link => 1,
            type => 'comments',
            sort => [ @$sort_by ],
        );
        my $doc = $sort[2];
        is( scalar @{ $doc->{data} || []}, 2, "... we fetched 2 resources, with sort" );
        my $ids = join "|", map $_->{id}, @{ $doc->{data} };
        my $expect = '12|5';
        is( $ids, $expect, "got them in the correct order" );

        TODO: {
            local $TODO = "Not yet implemented";
            like( $doc->{links}{self}, qr/&sort=/, "sort is included in the self link" );
        }
    }

    {
        my @sort_page = $dao->retrieve_all(
            type => 'comments',
            sort => [qw/ -id /],
            page => { offset => 1, limit => 1 },
        );
        my $doc = $sort_page[2];
        is( scalar @{ $doc->{data}}, 1, "... we only fetched one resource with sort+page" );
        is( $doc->{data}[0]{id}, 5, "... and it was what we wanted (id=5)" );

        my @sort_page_prev = $dao->retrieve_all(
            type => 'comments',
            sort => [qw/ -id /],
            page => { offset => 0, limit => 1 },
        );
        $doc = $sort_page_prev[2];
        is( scalar @{ $doc->{data}}, 1, "... fetched the previous result" );
        is( $doc->{data}[0]{id}, 12, "... and it was what we wanted (id=12)" );
    }
};

subtest '... retrieve' => sub {

    my @ret = $dao->retrieve(
        @TEST_ARGS_TYPE_ID,
        fields => { articles => [qw< title >] },
    );
    my $doc = $ret[2];

    is(ref $doc, 'HASH', '... the document we got is a HASH ref');

    my $data = $doc->{data};
    ok($data, '... the document has a `data` key');
    is(ref $data, 'HASH', '... the document has one resource');

    ok(scalar keys %{ $data->{attributes} } == 1, '... one key in `attributes`');
    ok(exists $data->{attributes}->{title}, '... the attribute `title` key exists');

    # Retrieve using false values as ids; should return nothing,
    # because the ids don't exist, but should not error.
    foreach my $id ( '', 0, '0E0', '0.0', '0 but true' ) {
        my @ret = $dao->retrieve( @TEST_ARGS_TYPE, id => $id );
        is_deeply(\@ret,
            [ 200, [], { data => undef, jsonapi => { version => '1.0' } } ],
            "... retrieve using $id as id works without errors",
        );
    }

    {
        my $fields = { people => [qw/ articles /], articles => [qw/id/] };
        my @ret = $dao->retrieve(
            type => 'articles',
            id => 2,
            include => [qw/authors/],
            fields  => $fields,
        );
        test_fields_response(\@ret, $fields);
   }
};

subtest '... retrieve relationships' => sub {

    my @ret = $dao->retrieve_relationships(
        @TEST_ARGS_TYPE_ID,
        req_path => '/articles/2/comments',
        send_doc_self_link => 1,
        rel_type => 'comments',
    );
    my $doc = $ret[2];

    is(ref $doc, 'HASH', '... the document we got is a HASH ref');

    my $data = $doc->{data};
    is(ref $data, 'ARRAY', '... the document has multiple resources');
    ok(scalar @{$data} == 2, '... the document has 2 resources');
    is(ref $data->[0], 'HASH', '... the 1st resouce is a HASH ref');
    ok(exists $data->[0]->{type}, '... the 1st resouce has a `type` key');
    ok(exists $data->[0]->{id}, '... the 1st resouce has an `id` key');
    is(keys( %{ $data->[0] } ), 2, "... that those are the only keys it returns");

    is(
        $doc->{links}{self},
        '/articles/2/comments',
        "... we get the correct self link"
    );

    {
        # page!
        my @page = $dao->retrieve_relationships(
            @TEST_ARGS_TYPE_ID,
            rel_type => "comments",
            req_path => '/articles/2/comments',
            page => {
                offset => 1,
                limit  => 1,
            },
        );
        my $doc = $page[2];
        is( scalar @{ $doc->{data}}, 1, "... we only fetched one resource, as requested" );

        is( $doc->{data}[0]{id}, 12, "... and the resource has id=12" )
            or diag("Honestly, this should break, since we are not using sort");
        my $expect = {
            first => '/articles/2/comments?page%5Blimit%5D=1&page%5Boffset%5D=0',
            prev  => '/articles/2/comments?page%5Blimit%5D=1&page%5Boffset%5D=0',
            self  => '/articles/2/comments?page%5Blimit%5D=1&page%5Boffset%5D=1',
        };
        my $links = $doc->{links};

        is_deeply(
            $links,
            $expect,
            "... all the pagination links are there"
        );
    }

    {
        # sort
        my @sort = $dao->retrieve_relationships(
            @TEST_ARGS_TYPE_ID,
            rel_type => "comments",
            sort => [qw/ -id /],
        );
        my $doc = $sort[2];
        is( scalar @{ $doc->{data}}, 2, "... we fetched 2 resources, with sort" );
        my $ids = join "|", map $_->{id}, @{ $doc->{data} };
        my $expect = "12|5";
        is( $ids, $expect, "got them in the correct order" );
    }
};

subtest '... retrieve by relationship' => sub {

    my @ret = $dao->retrieve_by_relationship(
        @TEST_ARGS_TYPE_ID,
        req_path => '/articles/2/authors',
        send_doc_self_link => 1,
        rel_type => 'authors',
    );
    my $doc = $ret[2];

    is(ref $doc, 'HASH', '... the document we got is a HASH ref');

    my $data = $doc->{data};
    is(ref $data, 'HASH', '... the document has one resource');
    ok(exists $data->{attributes}->{age}, '... the attribute `age` key exists');
    ok(exists $data->{attributes}->{gender}, '... the attribute `gender` key exists');
    ok(exists $data->{attributes}->{name}, '... the attribute `name` key exists');
    # Note that we requested the 'authors' relationship type, which is a collection
    # of people, so type for whatever was retrieved has to be 'person'
    is($data->{type}, 'people', '... retrieved document is of the correct type');

    is(
        $doc->{links}{self},
        '/articles/2/authors',
        "... we get the correct self link"
    );

    @ret = $dao->retrieve_by_relationship(
        @TEST_ARGS_TYPE_ID,
        rel_type => 'comments',
    );
    $doc = $ret[2];

    is(ref $doc, 'HASH', '... the document we got is a HASH ref');

    $data = $doc->{data};
    is(ref $data, 'ARRAY', '... the document has multiple resources');
    is(scalar(@$data), 2, "... two resources, in fact");

    {
        # page!
        my @page = $dao->retrieve_by_relationship(
            @TEST_ARGS_TYPE_ID,
            req_path => '/articles/2/comments',
            rel_type => "comments",
            page => {
                offset => 1,
                limit  => 1,
            },
        );
        my $doc = $page[2];
        is( scalar @{ $doc->{data}}, 1, "... we only fetched one resource, as requested" );

        is( $doc->{data}[0]{id}, 12, "... and the resource has id=12" )
            or diag("Honestly, this should break, since we are not using sort");
        my $expect = {
            first => '/articles/2/comments?page%5Blimit%5D=1&page%5Boffset%5D=0',
            prev  => '/articles/2/comments?page%5Blimit%5D=1&page%5Boffset%5D=0',
            self  => '/articles/2/comments?page%5Blimit%5D=1&page%5Boffset%5D=1',
            next  => '/articles/2/comments?page%5Blimit%5D=1&page%5Boffset%5D=2',
        };
        my $links = $doc->{links};

        is_deeply(
            $links,
            $expect,
            "... all the pagination links are there"
        );
    }

    {
        # sort
        my @sort = $dao->retrieve_by_relationship(
            @TEST_ARGS_TYPE_ID,
            rel_type => "comments",
            sort => [qw/ -id /],
        );
        my $doc = $sort[2];
        is( scalar @{ $doc->{data}}, 2, "... we fetched 2 resources, with sort(-d)" );
        my $ids = join "|", map $_->{id}, @{ $doc->{data} };
        my $expect = "12|5";
        is( $ids, $expect, "... got them in the correct order" );

        my @sort_title = $dao->retrieve_by_relationship(
            @TEST_ARGS_TYPE_ID,
            rel_type => "comments",
            sort => [qw/ -body /],
        );
        $doc = $sort_title[2];
        is( scalar @{ $doc->{data}}, 2, "... we fetched 2 resources, with sort(body)" );
        $ids = join "|", map $_->{id}, @{ $doc->{data} };
        is( $ids, $expect, "... got them in the correct order" );
    }
};

subtest '... update' => sub {

    my @orig   = $dao->retrieve( @TEST_ARGS_TYPE_ID );
    my @backup = $dao->retrieve( @TEST_ARGS_TYPE_ID );

    my $new_title = "Yadda yadda";
    my @update_ret = $dao->update(
        @TEST_ARGS_TYPE_ID,
        data => {
            @TEST_ARGS_TYPE_ID,
            attributes => {
                title  => $new_title,
            }
        },
    );
    is($update_ret[0], 202, "... default successful update returns a 202");
    my $doc = $update_ret[2];
    ok( exists $doc->{meta} && !exists $doc->{data}, "... which has a meta but no body" );

    my @new = $dao->retrieve( @TEST_ARGS_TYPE_ID );

    is(ref $doc, 'HASH', '... the document we got is a HASH ref');

    ok($doc->{meta}, "... (optional) meta member is present");

    $orig[2]->{data}{attributes}{title} = $new_title;
    delete $_->[2]{data}{attributes}{updated} for \@orig, \@new;
    is_deeply(\@orig, \@new, "... update works");

    $dao->update(
        @TEST_ARGS_TYPE_ID,
        data => {
            @TEST_ARGS_TYPE_ID,
            relationships => {
                authors => { type => "people", id => 777 },
            }
        }
    );

    $orig[2]->{data}{relationships}{authors}{data}{id} = 777;
    my @updated = $dao->retrieve( @TEST_ARGS_TYPE_ID );

    delete $updated[2]->{data}{attributes}{updated};
    is_deeply(\@updated, \@orig, "... can update one-to-one relationships");

    my $new_comments = [
        {type => comments => id => 55},
        {type => comments => id => 56},
    ];
    $dao->update(
        @TEST_ARGS_TYPE_ID,
        data => {
            @TEST_ARGS_TYPE_ID,
            relationships => {
                comments => $new_comments,
            },
        }
    );
    @updated = $dao->retrieve( @TEST_ARGS_TYPE_ID );

    delete $updated[2]->{data}{attributes}{updated};
    $orig[2]->{data}{relationships}{comments}{data} = $new_comments;
    is_deeply(\@updated, \@orig, "... and many-to-many");

    my @res = $dao->update(
        @TEST_ARGS_TYPE_ID,
        data => {
            @TEST_ARGS_TYPE_ID,
            relationships => {
                authors  => undef,
                comments => []
            }
        }
    );
    @updated = $dao->retrieve( @TEST_ARGS_TYPE_ID );

    delete $orig[2]->{data}{relationships};
    delete $updated[2]->{data}{attributes}{updated};
    is_deeply(\@updated, \@orig, "... can clear relationships via update");

    my $data_for_restore = { %{ $backup[2]->{data} } };
    my $relationships = delete $data_for_restore->{relationships};
    $data_for_restore->{relationships}{$_} = $relationships->{$_}{data}
        for keys %$relationships;
    $dao->update( @TEST_ARGS_TYPE_ID, data => $data_for_restore );
    @updated = $dao->retrieve(@TEST_ARGS_TYPE_ID);

    my $backup_updated = delete $backup[2]->{data}{attributes}{updated};
    delete $updated[2]->{data}{attributes}{updated};
    is_deeply(\@updated, \@backup, "... successfully 'restored' the comment");

    my @update_200 = $dao->update( type => comments => id => 12, data => { type => comments => id => 12, attributes => { body => "This changes nothing extra" } }, respond_to_updates_with_200 => 1 );
    is($update_200[0], 200, "... can set the DAO to return 200 on updates");
    ok( exists $doc->{meta} && !exists $doc->{data}, "... which has a meta and no data, because it has no side effects");

    @update_200 = $dao->update(
        @TEST_ARGS_TYPE_ID,
        req_path => '/articles/2',
        data => {
            @TEST_ARGS_TYPE_ID,
            attributes => {
                title => "This changes updated"
            }
        },
        respond_to_updates_with_200 => 1,
    );
    my $new_updated = delete $update_200[2]->{data}{attributes}{updated};
    isnt($new_updated, $backup_updated, "... the updated date auto-changed,");
    is_deeply(
        \@update_200,
        [
            200,
            [],
            {
                data => {
                    type => 'articles',
                    id   => 2,
                    attributes => {
                        created => '2015-06-22 14:56:29',
                        body    => 'The 2nd shortest article. Ever.',
                        title   => 'This changes updated',
                        status  => 'ok'
                    },
                    links => { self => '/articles/2' },
                    relationships => {
                        comments => {
                            data => [
                                { type => 'comments', id => 5 },
                                { type => 'comments', id => 12 }
                            ],
                            links => {
                                related => '/articles/2/comments',
                                self    => '/articles/2/relationships/comments'
                            },
                        },
                        authors => {
                            data => { type => 'people', id => 88 },
                            links => {
                                related => '/articles/2/authors',
                                self    => '/articles/2/relationships/authors'
                            },
                        }
                    }
                },
                jsonapi => { 'version' => '1.0' },
                meta    => {
                    detail => 'successfully modified /articles/2 => {"attributes":{"title":"This changes updated"},"id":2,"relationships":null,"type":"articles"}'
                }
            }],
        "...so now it returns a full resource object + meta"
    );

};

subtest '... delete_relationships' => sub {

    my @res = $dao->delete_relationships(
        @TEST_ARGS_TYPE_ID,
        req_path => '/articles/2/comments',
        rel_type => "comments",
        data     => [
            { type => comments => id => 5 },
        ],
    );
    is_deeply(
        \@res,
         [
            202,
            [],
            {
              jsonapi => { version => '1.0' },
              meta    => { detail  => 'successfully modified /articles/2/comments => [{"id":5,"type":"comments"}]' }
            }
         ],
         "... can delete as expected",
    );

    my @retrieve = $dao->retrieve( @TEST_ARGS_TYPE_ID );

    delete $retrieve[2]->{data}{attributes}{updated};
    my $expect = [
            200,
            [],
            {
              data    => {
                           attributes
                                   => {
                                        body    => 'The 2nd shortest article. Ever.',
                                        created => '2015-06-22 14:56:29',
                                        status  => 'ok',
                                        title   => 'This changes updated',
                                      },
                           links   => { self => '/articles/2' },
                           id      => 2,
                           relationships
                                   => {
                                        authors  => { data => {
                                                      id   => 88,
                                                      type => 'people'
                                                    },
                                                    links => {
                                                      related => '/articles/2/authors',
                                                      self    => '/articles/2/relationships/authors'
                                                    }
                                        },
                                        comments => { data => [
                                                      {
                                                        id   => 12,
                                                        type => 'comments'
                                                      }
                                                    ],
                                                      links => {
                                                                 related => '/articles/2/comments',
                                                                 self    => '/articles/2/relationships/comments'
                                                               }                                                     }
                                      },
                           type    => 'articles'
                         },
              jsonapi => { version => '1.0' }
            }
          ];
    is_deeply(\@retrieve, $expect, "... and the correct changes are retrieved");

    # try the same delete again
    subtest '... try to delete the same relationship again' => sub {
        my @res2 = $dao->delete_relationships(
            @TEST_ARGS_TYPE_ID,
            req_path => '/articles/2/comments',
            rel_type => "comments",
            data     => [
                { type => comments => id => 5 },
            ],
        );
        is($res2[0], 204, '... got the correct status code');
        ok(!$res2[2], '... and no body');
    };

};

subtest '... create + create_relationship' => sub {

    my ($status_author, $headers_author, $doc_for_author_create) = $dao->create(
        type => 'people',
        data => {
            type => 'people',
            attributes => {
                name => 'Doof',
                age  => 33,
                gender => 'female',
            },
        },
    );
    is( $status_author, 201, "... correct status for create" );
    # Brittle...
    is_deeply(
        $headers_author,
        [ Location => '/people/92' ],
        "... has the Location header for the create"
    );
    ok(!exists $doc_for_author_create->{errors}, "... no errors, created the new person");
    unlike($doc_for_author_create->{data}{id}, qr/\A(?:0|42|88|91|)\z/, "... and got a new id for them");

    my $author_id = $doc_for_author_create->{data}{id};

    my ($status_article, $headers_article, $article_doc) = $dao->create(
        @TEST_ARGS_TYPE,
        data => {
            type => 'articles',
            attributes => {
                title => "Brand new test article!",
                body  => "With a brand new body!",
            },
            relationships => {
                authors => { type => 'people', id => $author_id }
            },
        }
    );

    is( $status_article, 201, "... correct status for article create" );
    is_deeply( $headers_article, [ Location => '/articles/4' ], "... has the Location header" );

    my ($status_comment, $headers_comment, $comment_doc) = $dao->create(
        type => 'comments',
        data => {
            type => 'comments',
            attributes => {
                body => "Great insight",
            },
        },
    );

    is( $status_comment, 201, "... correct status for comment create" );
    my $comment_id = $comment_doc->{data}{id};

    my $article_id = $article_doc->{data}{id};
    my @create_rel = $dao->create_relationships(
        @TEST_ARGS_TYPE,
        id       => $article_id,
        rel_type => "comments",
        data => [
            { type => comments => id => $comment_id },
        ],
    );

    # Let's use the work so far to test that retrieve_all+include shouldn't
    # return more than one resource per type&id pair
    {
        # Now $author_id will be the author of two articles
        my @update_rel = $dao->update_relationships(
            type     => 'articles',
            id       => 2,
            rel_type => 'authors',
            data     => { type => people => id => $author_id }
        );
        my @retrieve_all = $dao->retrieve_all(
            send_doc_self_link => 1,
            type => 'articles', include => [qw/authors/],
        );
        my @author_ids = sort { $a <=> $b }
                      map $_->{id}, @{ $retrieve_all[2]->{included} || [] };
        my %uniq = map +($_=>1), @author_ids;
        # http://jsonapi.org/format/#document-compound-documents
        # A compound document MUST NOT include more than one resource object for each type and id pair.
        is(scalar(@author_ids), scalar(keys %uniq), "include has no duplicates")
            or diag("include has duplicates! Got <@author_ids>");
    }

    my @retrieved = $dao->retrieve(
        @TEST_ARGS_TYPE,
        id      => $article_id,
        include => [qw/ authors comments /],
    );
    delete @{ $retrieved[2]->{data}{attributes} }{qw/ created status updated /};
    @{ $retrieved[2]->{included} } =  sort { $a->{type} cmp $b->{type} } @{ $retrieved[2]->{included} };

    my $expect = {
           data     => {
               attributes
                       => {
                            body  => 'With a brand new body!',
                            title => 'Brand new test article!'
                          },
               id      => 4,
               links   => { self => "/articles/$article_id" },
               relationships
                       => {
                            authors  => {
                                          data  => {
                                                     id   => $author_id,
                                                     type => 'people'
                                                   },
                                          links => {
                                                     related => "/articles/$article_id/authors",
                                                     self    => "/articles/$article_id/relationships/authors"
                                                   }
                                        },
                            comments => {
                                          data  => [{
                                                     id   => 13,
                                                     type => 'comments'
                                                   }],
                                          links => {
                                                     related => "/articles/$article_id/comments",
                                                     self    => "/articles/$article_id/relationships/comments"
                                                   }
                                        }
                          },
               type    => 'articles'
           },
           included => [
                         {
                           attributes
                                 => { body => 'Great insight' },
                           id    => 13,
                           type  => 'comments',
                           links => { self => '/comments/13' },
                         },
                         {
                           attributes
                                 => {
                                      age    => 33,
                                      gender => 'female',
                                      name   => 'Doof'
                                    },
                           id    => 92,
                           type  => 'people',
                           links => { self => '/people/92' },
                         }
                       ],
           jsonapi  => { version => '1.0' }
         };


    is_deeply($retrieved[2], $expect, "... retrieve with include returns all we have done");

    my @update_rel = $dao->update_relationships(
        @TEST_ARGS_TYPE,
        req_path => "/articles/$article_id/comments",
        id       => $article_id,
        rel_type => "comments",
        data     => [],
    );
    is_deeply( \@update_rel, [
            202,
            [],
            {
              jsonapi => { version => '1.0' },
              meta    => { detail  => "successfully modified /articles/$article_id/comments => []" }
            }
          ], "... update_relationships cleared comments" );

    my @delete = $dao->delete( type => "people", id => $author_id );
    is_deeply( \@delete,
        [
            200,
            [],
            {
              jsonapi => { version => '1.0' },
              meta    => { detail  => "successfully deleted the resource /people/$author_id" }
            }
        ], "... delete cleared the author" );

    my @retrieved_again = $dao->retrieve(
        @TEST_ARGS_TYPE,
        id      => $article_id,
        include => [qw/ authors comments /],
    );
    delete @{ $retrieved_again[2]->{data}{attributes} }{qw/ created status updated /};

    my $final_expect = {
        'jsonapi' => { 'version' => '1.0' },
        'data'    => {
            'type'       => 'articles',
            'attributes' => {
                'body'  => 'With a brand new body!',
                'title' => 'Brand new test article!'
            },
            links   => { self => "/articles/$article_id" },
            'relationships' => {
                'authors' => {
                    'data' => {
                        'type' => 'people',
                        'id'   => $author_id,
                    },
                    links => {
                        related => "/articles/$article_id/authors",
                        self    => "/articles/$article_id/relationships/authors",
                    },
                }
            },
            'id' => $article_id,
        }
    };
    is_deeply($retrieved_again[2], $final_expect, "... including missing resources works");


    # Special cases; updating a one-to-one lets you pass undef.
    # See http://jsonapi.org/format/#crud-updating-to-one-relationships
    {
        my @author_update_rel = $dao->update_relationships(
            @TEST_ARGS_TYPE,
            req_path => "/articles/$article_id/authors",
            id       => $article_id,
            rel_type => "authors",
            data     => undef,
        );
        is_deeply(\@author_update_rel, [202, [], {
            meta    => { detail => 'successfully modified /articles/4/authors => null' },
            jsonapi => { 'version' => '1.0' },
        }], "... clearing out a one-to-one works (using update_relationships)");

        my @author_update = $dao->update(
            @TEST_ARGS_TYPE,
            req_path => "/articles/$article_id",
            id       => $article_id,
            data     => {
                type => "articles",
                id   => $article_id,
                relationships => {
                    authors  => undef,
                    comments => [],
                }
            },
        );
        is_deeply(\@author_update, [202, [], {
            meta => {
                detail => 'successfully modified /articles/4 => {"attributes":null,"id":4,"relationships":{"authors":null,"comments":[]},"type":"articles"}'
            },
            jsonapi => { 'version' => '1.0' },
        }], "... clearing out a one-to-one works (using update)");
    }

};

sub test_fields_response {
    my ($response, $fields) = @_;

    my $included = $response->[2]{included} || [];
    my $data     = $response->[2]{data};
    $data = [ $data ] if ref $data ne 'ARRAY';

    foreach my $resource_orig ( @$included, @$data ) {
        my $resource     = { %$resource_orig };
        my ($type, $id) = @{$resource}{qw/type id/};
        my $has_fields = $fields->{$type};
        delete @{$resource->{$_}}{@$has_fields} for qw/attributes relationships/;
        is_deeply(
            $resource,
            {
                type          => $type,
                id            => $id,
                attributes    => {},
                relationships => {},
                links         => { self => "/$type/$id" },
            },
            "... fields fetches exactly what we asked for"
        ) or diag(Dumper($resource_orig));
    }

}

done_testing;
