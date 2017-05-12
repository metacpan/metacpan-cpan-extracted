use lib 't/lib';
use Test::More;
use Test::Riak;

# store and get links
test_riak {
    my ($client, $bucket_name) = @_;

    my $bucket = $client->bucket($bucket_name);
    my $obj = $bucket->new_object("foo", [2]);
    my $obj1 = $bucket->new_object("foo1", {test => 1})->store;
    my $obj2 = $bucket->new_object("foo2", {test => 2})->store;
    my $obj3 = $bucket->new_object("foo3", {test => 3})->store;
    $obj->add_link($obj1);
    $obj->add_link($obj2, "tag");
    $obj->add_link($obj3, "tag2!@&");
    $obj->store;
    $obj = $bucket->get("foo");
    is $obj->has_links, 3, 'got 3 links';
};

# link walking
test_riak {
    my ($client, $bucket_name) = @_;

    my $bucket = $client->bucket($bucket_name);
    my $obj    = $bucket->new_object("foo", [2]);
    my $obj1   = $bucket->new_object("foo1", {test => 1})->store;
    my $obj2   = $bucket->new_object("foo2", {test => 2})->store;
    my $obj3   = $bucket->new_object("foo3", {test => 3})->store;
    $obj->add_link($obj1)->add_link($obj2, "tag")->add_link($obj3, "tag2!@&");
    $obj->store;
    $obj = $bucket->get("foo");
    my $results = $obj->link($bucket_name)->run();
    is scalar @$results, 3, 'got 3 links via links walking';
    $results = $obj->link($bucket_name, 'tag')->run;
    is scalar @$results, 1, 'got one link via link walking';
};


