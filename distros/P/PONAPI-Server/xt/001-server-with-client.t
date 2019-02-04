#!perl

use strict;
use warnings;

use Test::More;
use Plack::Test::Server;

use Data::Dumper;

use PONAPI::Server;
use IPC::Cmd qw/can_run/;

delete @ENV{qw/ HTTP_PROXY http_proxy /};

# Rather than just testing PONAPI::Client, let's make sure we're
# working on other backends too.  We always test PONAPI::Client,
# but if available, we'll also test HTTP::Tiny and curl on the
# command line.
my $have_ponapi_client = do { local $@; !!eval { require PONAPI::Client; 1 } };
my $have_http_tiny     = do { local $@; !!eval { require HTTP::Tiny; 1 } };
my $have_curl          = can_run('curl');

if ( !$have_ponapi_client && !$have_http_tiny && !$have_curl ) {
    plan skip_all => 'Client cannot be loaded, not running these tests'
}

my $media_type = 'application/vnd.api+json';

my $author_attributes = {
    name   => 'New!',
    age    => 11,
    gender => 'female',
};

my $article_2 = {
  data => {
    type       => "articles",
    id         => 2,
    links      => { self => "/articles/2" },
    attributes => {
      body    => "The 2nd shortest article. Ever.",
      created => "2015-06-22 14:56:29",
      status  => "ok",
      title   => "A second title",
      updated => "2015-06-22 14:56:29"
    },
    relationships => {
      authors => {
        data => {
          id   => 88,
          type => "people"
        },
        links => {
          related => "/articles/2/authors",
          self    => "/articles/2/relationships/authors"
        }
      },
      comments => {
        data => [
          {
            id   => 5,
            type => "comments"
          },
          {
            id   => 12,
            type => "comments"
          }
        ],
        links => {
          related => "/articles/2/comments",
          self    => "/articles/2/relationships/comments"
        }
      }
    },
  },
  included => [
    {
      attributes => {
        age => 18,
        gender => "male",
        name => "Jimmy"
      },
      id    => 88,
      links => { self => "/people/88" },
      type  => "people"
    },
    {
      type       => "comments",
      id         => 5,
      attributes => { body => "First!"      },
      links      => { self => "/comments/5" },
    },
    {
      type       => "comments",
      id         => 12,
      attributes => { body => "I like XML better" },
      links      => { self => "/comments/12"      },
    }
  ],
  jsonapi => { version => "1.0"         },
  links   => { self    => "/articles/2" },
};

my @common = ( type => articles => id => 2 );

sub basic_retrieve_all_test {
    my ($status, $res, $expected_ids_in_order) = @_;

    my $ids    = join '|', map $_->{id}, @{ $res->{data} };
    my $expect = join '|', @$expected_ids_in_order;

    is($ids, $expect, "... retrieve_all works as expected ($expect)")
        or diag(Dumper($res));
    is($status, 200, "... and has the correct status");
}

sub status_is_200 {
    is(shift(), 200, '... status is good');
}

sub _get_a_new_author {
    my ($client) = @_;

    return $client->create(
        type => 'people',
        data => {
            type       => 'people',
            attributes => $author_attributes,
        }
    )->{data};
}

sub _get_a_new_comments {
    my ($client) = @_;

    return $client->create(
        type => 'comments',
        data => {
            type => 'comments',
            attributes => { body => "Text yadda " . rand(250) },
        },
    )->{data};
}

foreach my $implementation (
    ($have_ponapi_client ? 'PONAPI::Client'             : ()),
    ($have_http_tiny     ? 'PONAPI::Client::HTTP::Tiny' : ()),
    ($have_curl          ? 'PONAPI::Client::cURL'       : ()),
) {

    my $app = Plack::Test::Server->new(PONAPI::Server->new(
        'ponapi.sort_allowed' => 1
    )->to_app());

    if ( !$app ) {
        fail('Failed to start a PSGI test server?');
        done_testing;
        exit;
    }

    my $port   = $app->port;
    subtest "... $implementation" => sub {
        my $client = $implementation->new( port => $port );

        ok($client, '..we can create a client pointing to our test server');

        subtest '... retrieve_all' => sub {
            my ($status, $res) = $client->retrieve_all(type => 'articles');
            basic_retrieve_all_test($status, $res, [1, 2, 3]);

            my ($status_2, $res_sorted) = $client->retrieve_all(
                type => 'articles',
                sort => [qw/-id/],
            );
            basic_retrieve_all_test($status_2, $res_sorted, [3, 2, 1]);

            my ($status_sorted, $res_sorted_page) = $client->retrieve_all(
                type => 'articles',
                sort => [qw/-id/],
                page => {
                    offset => 1,
                    limit  => 1,
                },
            );
            basic_retrieve_all_test($status_sorted, $res_sorted_page, [2]);
            is_deeply(
                $res_sorted_page->{links},
                {
                    'self'  => '/articles?page%5Blimit%5D=1&page%5Boffset%5D=1&sort=-id',
                    'next'  => '/articles?page%5Blimit%5D=1&page%5Boffset%5D=2&sort=-id',
                    'first' => '/articles?page%5Blimit%5D=1&page%5Boffset%5D=0&sort=-id',
                    'prev'  => '/articles?page%5Blimit%5D=1&page%5Boffset%5D=0&sort=-id',
                },
                "... paging works (sort of)"
            ) or diag(Dumper($res_sorted_page));
        };

        subtest '... retrieve' => sub {
            my ($status, $res) = $client->retrieve(@common);
            my $clone = { %$article_2 };
            delete $clone->{included};
            is_deeply($res, $clone, "...we retrieved the correct user");
            status_is_200($status);

            # Let's test all of the options here.
            my ($status_fields, $fields_res) = $client->retrieve(@common,
                fields => { articles => [qw/title/] },
            );
            delete $fields_res->{data}{links};
            is_deeply(
                $fields_res->{data},
                {
                    @common,
                    attributes => { title => "A second title" },
                },
                "... filtering the main resource's attributes works",
            );
            status_is_200($status_fields);

            my ($fields_rel_status,$fields_rel_res) = $client->retrieve(@common,
                fields => { articles => [qw/authors/] },
            );
            delete $fields_rel_res->{data}{relationships}{authors}{links};
            is_deeply(
                $fields_rel_res->{data}{relationships},
                { authors => { data => { type => people => id => 88 } }, },
                "... filtering the main resource's attributes works",
            ) or diag(Dumper($fields_rel_res));
            status_is_200($fields_rel_status);
        };

        subtest '... retrieve_by_relationship' => sub {
            my ($status1, $res1) = $client->retrieve_by_relationship(@common, rel_type => 'authors');
            delete $res1->{data}{relationships};
            is_deeply(
                [ $res1->{data} ],
                [ grep $_->{type} eq 'people', @{$article_2->{included}} ],
                "... got the right data for a one-to-one"
            ) or diag(Dumper($res1));
            status_is_200($status1);

            my ($status2, $res2) = $client->retrieve_by_relationship(@common, rel_type => 'comments');
            delete $_->{relationships} for @{ $res2->{data} };
            is_deeply(
                $res2->{data},
                [ grep $_->{type} eq 'comments', @{$article_2->{included}} ],
                "... got the right data for a one-to-many"
            ) or diag(Dumper($res2));
            status_is_200($status2);
        };

        subtest '... retrieve_relationships' => sub {
            my ($status1, $res1) = $client->retrieve_relationships(@common, rel_type => 'authors');
            is_deeply(
                $res1->{data},
                $article_2->{data}{relationships}{authors}{data},
                "... fetched the correct one-to-one relationship"
            ) or diag(Dumper($res1));
            status_is_200($status1);

            my ($status2, $res2) = $client->retrieve_relationships(@common, rel_type => 'comments');
            is_deeply(
                $res2->{data},
                $article_2->{data}{relationships}{comments}{data},
                "... fetched the correct one-to-many relationship",
            ) or diag(Dumper($res2));
            status_is_200($status2);
        };

        subtest '... create + update + delete (without relationships)' => sub {
            my ($create_status, $create_res) = $client->create(
                type => 'people',
                data => { attributes => $author_attributes },
            );
            isa_ok( $create_res->{data}, 'HASH', ".. created and got data back" )
                or diag(Dumper($create_res));
            is($create_status, 201, "... and got the correct status");

            my ($retrieve_status, $retrieve_res) = $client->retrieve( $create_res->{data} );
            is_deeply(
                $retrieve_res->{data}{attributes},
                $author_attributes,
                ".. and we retrieved it just fine",
            ) or diag(Dumper($retrieve_res));
            status_is_200($retrieve_status);

            foreach my $iteration (1..5) {
                my ($update_status, $update_res) = $client->update(
                    %{ $create_res->{data} },
                    data => {
                        attributes => { name => 'Another name', },
                    },
                );
                like(
                    $update_res->{meta}{detail},
                    qr/\Asuccessfully modified/,
                    ".. updated attributes successfully ( $iteration )"
                );
                # This could be 200, if the server was started with
                # 'ponapi.respond_to_updates_with_200' => 1
                is($update_status, 202, "... and got the correct status");
            }

            my ($del_status, $delete_res) = $client->delete( $create_res->{data} );
            like(
                $delete_res->{meta}{detail},
                qr/\Asuccessfully deleted the resource/,
                "... and deleted it"
            );
            # Could be 204 depending on the implementation, but our
            # DAO always returns a meta, so it's fairly safe to test this
            status_is_200($del_status);

            my ($del_status_agai, $delete_res_again) = $client->delete( $create_res->{data} );
            like(
                $delete_res->{meta}{detail},
                qr/\Asuccessfully deleted the resource/,
                "... and deleted it again, without any issues"
            );
            status_is_200($del_status);
        };

        subtest '... (update|create|delete)_relationships' => sub {
            # First, let's create an author, two comments,
            # and then add them to articles.
            my $author   = _get_a_new_author($client);
            my @comments = map _get_a_new_comments($client), 1, 2;

            my ($create_status, $create_response) = $client->create(
                type => 'articles',
                data => {
                    attributes => {
                        title => 'foo',
                        body  => 'bar',
                    },
                }
            );
            is($create_status, 201, "... and got the correct status");
            my $article = $create_response->{data};

            # Let's add some relationships:
            my ($create_rel_status, $create_rel) = $client->create_relationships(
                %$article,
                rel_type => 'comments',
                data     => \@comments,
            );
            like( $create_rel->{meta}{detail}, qr/\Asuccessfully modified/ );
            is($create_rel_status, 202, "... and the proper status");

            my ($retrieve_rel_status, $retrieve_rel) = $client->retrieve_relationships(
                %$article, rel_type => 'comments',
            );
            is_deeply( $retrieve_rel->{data}, \@comments, "... successfully added two comments to the article" );
            status_is_200($retrieve_rel_status);

            my ($status_retrieve_backwards, $retrieve_rel_backwards) =
                $client->retrieve_relationships(
                    %{$comments[0]}, rel_type => 'articles',
                );
            is_deeply(
                $retrieve_rel_backwards->{data},
                $article,
                "... and we can fetch the article going by the comments, too",
            );
            status_is_200($status_retrieve_backwards);

            foreach my $iteration (1..5) {
                my ($code, $delete_rel) = $client->delete_relationships(
                    %$article,
                    rel_type => 'comments',
                    data     => [ $comments[0] ],
                );

                if ( $iteration == 1 ) {
                    like(
                        $delete_rel->{meta}{detail},
                        qr/\Asuccessfully modified/,
                        "... delete relationships (try $iteration)"
                    );
                    is($code, 202, "... and the right code");
                }
                else {
                    ok( !$delete_rel, "...no body for iteration $iteration" );
                    is(
                        $code,
                        204,
                        "... no body, but status is 204, so that's fine (try $iteration)"
                    );
                }
            }

            # First, try updating the authors, which is one-to-one
            foreach my $test_data (
                [ 'authors' => $author    ],
                [ 'authors' => undef      ],
                [ 'authors' => \@comments ],
                [ 'authors' => []         ],
            )
            {
                my ($rel_type, $data) = @$test_data;
                foreach my $iteration (1..5) {
                    my $update_rel = $client->update_relationships(
                        %$article, rel_type => 'authors',
                        data => $author,
                    );

                    my $one_to   = ref($data||'') eq 'ARRAY' ? 'one-to-many' : 'one-to-one';
                    my $has_data = (!defined($data) || (ref $data eq 'ARRAY' && !@$data))
                                 ? 'without data'
                                 : 'with data';
                    like(
                        $update_rel->{meta}{detail},
                        qr/\Asuccessfully modified /,
                        "... update_relationships ($one_to) works ($rel_type, $has_data, try $iteration)"
                    );
                }
            }
        };

        subtest '... create + update + delete (with relationships)' => sub {
            my $author   = _get_a_new_author($client);
            my @comments = map _get_a_new_comments($client), 1, 2;

            my $create_res = $client->create(
                type => 'articles',
                data => {
                    attributes => {
                        title => "Base title",
                        body  => "Base body",
                    },
                    relationships => {
                        authors  => $author,
                        comments => \@comments,
                    },
                },
            );

            like(
                $create_res->{meta}{detail},
                qr/successfully created the resource/,
                "... created the resource"
            ) or diag(Dumper($create_res));

            my $json = JSON::MaybeXS->new->allow_nonref->utf8->canonical;
            foreach my $rels (
                { comments => \@comments, authors => $author },
                { comments => [], authors => $author },
                { comments => \@comments, authors => undef },
                { comments => [], authors => undef },
                { comments => [$comments[1]], authors => $author },
                { comments => [], authors => undef },
            )
            {
                foreach my $i (1..5) {
                    my $update_res = $client->update(
                        %{ $create_res->{data} },
                        data => {
                            attributes    => { title => 'Update!' },
                            relationships => $rels,
                        }
                    );
                    my $data_json = $json->encode($rels);
                    like(
                        $update_res->{meta}{detail},
                        qr/\Asuccessfully modified/,
                        "... successful update with $data_json (try $i)"
                    ) or diag( Dumper($update_res) );
                }
            }
        };

    }; # '... $test_name' subtest
}

BEGIN {
    {
        package PONAPI::Client::Mock;

        use Moose;

        with 'PONAPI::Document::Builder::Role::HasPagination';

        has port => (
            is => 'ro',
        );

        has json => (
            is => 'ro',
            default => sub { JSON::MaybeXS->new->allow_nonref->utf8->canonical },
        );

        my %action_to_http_method = (
            create               => 'POST',
            create_relationships => 'POST',

            update               => 'PATCH',
            update_relationships => 'PATCH',

            delete               => 'DELETE',
            delete_relationships => 'DELETE',
        );

        sub AUTOLOAD {
            our $AUTOLOAD;
            my $self = shift;
            my %args = @_ == 1 ? %{ $_[0] } : @_;

            my $autoloading_method = (split /::/, $AUTOLOAD)[-1];
            my $method   = $action_to_http_method{$autoloading_method} || 'GET';

            my $type     = delete $args{type};
            my $id       = delete $args{id};
            my $rel_type = delete $args{rel_type};

            my $body;

            if ( exists $args{data} ) {
                my $data = delete $args{data};
                if ( ref($data) eq 'HASH' ) {
                    $data->{type} //= $type;
                    $data->{id}   //= $id if defined $id;
                }
                $body = $self->json->encode( { data => $data } );
            }

            my $relationships = $autoloading_method =~ /relationships\z/i
                ? 'relationships'
                : undef;

            my $path = join '/', grep defined,
                '', $type, $id, ( $id ? ($relationships, $rel_type) : () );

            my $query_string = $self->_hash_to_uri_query(\%args);

            return $self->_send_ponapi_request(
                %args,
                path         => $path,
                query_string => $query_string,
                body         => $body,
                method       => $method,
            );
        }
    }

    {
        package PONAPI::Client::HTTP::Tiny;

        use Moose;

        use Data::Dumper;
        use JSON::MaybeXS qw/decode_json/;

        extends 'PONAPI::Client::Mock';

        sub _send_ponapi_request {
            my ($self, %args) = @_;

            my $url = 'http://127.0.0.1:' . $self->port . $args{path};
            $url   .= "?$args{query_string}" if $args{query_string};

            my $mt_key = $args{body} ? 'Content-Type' : 'Accept';

            my $response = HTTP::Tiny->new()->request(
                $args{method} => $url,
                {
                    headers => { $mt_key => $media_type },
                    ( $args{body} ? (content => $args{body}) : () ),
                }
            );

            return $response->{status} unless $response->{content};

            ::is(
                $response->{headers}{'content-type'},
                $media_type,
                "..got the expected media type",
            ) or diag(Dumper($response));

            my ($content, $failed, $e);
            {
                local $@;
                eval  { $content = decode_json($response->{content}) }
                    or do { ($failed, $e) = (1, $@||'Unknown error')     };
            }

            if ( $failed ) {
                ::diag("Failed to decode the response content: $@\n" . Dumper($response));
            }

            return $response->{status}, $content;
        }
    }

    # Since cURL testing can be affected by all sort of unplanned things,
    # we tread *very* lightly; failing any of these tests won't actually cause
    # the test suite to fail!
    # While we want these to be tested and passing, if everything else is
    # working,

    {
        package PONAPI::Client::cURL;

        use Moose;

        use JSON::MaybeXS qw/decode_json/;
        use IPC::Cmd qw/can_run run/;

        extends 'PONAPI::Client::Mock';

        sub BUILD {
            bless Test::More->builder, "Test::Builder::ButReallyLaxAboutFailing";
        }

        sub _send_ponapi_request {
            my ($self, %args) = @_;

            my $url = 'http://127.0.0.1:' . $self->port . $args{path};
            $url   .= "?$args{query_string}" if $args{query_string};

            my $mt_key = $args{body} ? 'Content-Type' : 'Accept';

            my $curl_path = can_run('curl');

            my @cmd = (
                $curl_path,
                '-s',
                '-X'  => $args{method},
                '-w'  => '\n%{http_code}',
                '-H'  => "$mt_key: $media_type",
                $url,
                ($args{body} ? ('-d' => $args{body}) : ()),
            );

            my ( $success, $error, $full_buf, $stdout_buf, $stderr_buf ) = run(
                command => \@cmd, timeout => 5
            );

            my ($content, $status) = ($stdout_buf->[0] || '') =~ /(.*)\n([0-9]+)\z/s;

            return $status, ($success && $content) ? decode_json($content) : undef;
        }

        sub DEMOLISH {
            bless Test::More->builder, 'Test::Builder';
        }
    }

    {
        package Test::Builder::ButReallyLaxAboutFailing;

        our @ISA = 'Test::Builder';

        my $no_good;

        sub _enough_messing_around {
            my ($self) = @_;

            if ( !$self->is_passing ) {
                $self->diag(<<'EORANT');
Tsk. Something failed in the cURL test. Nothing else was failing
up to this point, so it's likely harmless.  We're just going to
pretend that that test passed and skip the rest of the cURL bit.
EORANT

                $self->is_passing(1);
                $self->{Curr_Test} = 0;
                $no_good = 1;
                $self->plan(skip_all => "Skipping the rest of the cURL tests");
            }
        }

        sub subtest {
            my $self = shift;
            return if $no_good;
            return $self->SUPER::subtest(@_);
        }

        foreach my $function ( qw/ok is like is_deeply/ ) {
            my $glob = do { no strict 'refs'; \*{ $function } };
            *$glob = sub {
                my $self   = shift;
                my $method = "SUPER::$function";
                my $ret    = $self->$method(@_);
                $self->_enough_messing_around;
                return $ret;
            };
        }
    }
}

done_testing;
