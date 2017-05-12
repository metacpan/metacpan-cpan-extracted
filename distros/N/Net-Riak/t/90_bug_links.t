use lib 't/lib';
use Test::More;
use Test::Riak;

test_riak {
    my ($client, $bucket_name) = @_;

    # set up a bucket containing two person/user records and store them
    my $bucket_one = $client->bucket($bucket_name);

    my $ref1 = {
        username => 'griffinp',
        fullname => 'Peter Griffin',
        email => 'peter@familyguy.com'
    };
    my $ref2 = {
        username => 'griffins',
        fullname => 'Stewie Griffin',
        email => 'stewie@familyguy.com'
    };

    ok $bucket_one->new_object( $ref1->{username} => $ref1 )->store(1,1), 'new object stored';
    ok $bucket_one->new_object( $ref2->{username} => $ref2 )->store(1,1), 'new object stored';

    # create another bucket to store some data that will link to users
    my $bucket_two = $client->bucket("$bucket_name\_2");

    # create the object
    my $item_data = {
        a_number  => rand(),
        some_text => 'e86d62c91139f328df5f05e9698a248f',
        epoch     => time()
    };
    ok my $item = $bucket_two->new_object( '25FCBA57-8D75-41B6-9E5A-0E2528BB3342' => $item_data ), 'store new object to second bucket';

    # create a link to each person that is stored in bucket 'ONE' and associate the link
    # with the $item object
    foreach my $person ( $ref1, $ref2 ) {
        my $link = Net::Riak::Link->new(
            bucket => $bucket_one,
            key    => $person->{email},
            tag    => 'owners'
        );
        ok $item->add_link( $link ), 'link added to object';
    }

    # store to Riak
    ok $item->store( 1, 1 ), 'object stored';

    my $test_links = $bucket_two->get('25FCBA57-8D75-41B6-9E5A-0E2528BB3342', [1]);
    my $links = $test_links->links;

    is $links->[0]->key, 'peter@familyguy.com', 'good owner for first link';
    is $links->[1]->key, 'stewie@familyguy.com', 'good owner for second link';

    $test_links->remove_link($links->[0]);
    $links = $test_links->links;
    is $links->[0]->key, 'stewie@familyguy.com', 'good owner for second link after a remove link';
};
