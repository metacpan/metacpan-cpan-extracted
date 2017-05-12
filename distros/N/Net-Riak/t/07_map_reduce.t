use lib 't/lib';
use Test::More;
use Test::Riak;

# JS source map reduce
test_riak {
    my ($client, $bucket_name) = @_;
    my $bucket = $client->bucket($bucket_name);
    my $obj    = $bucket->new_object('foo', [2])->store;
    my $result =
      $client->add($bucket_name, 'foo')
      ->map("function (v) {return [JSON.parse(v.values[0].data)];}")->run;
    is_deeply $result, [[2]], 'got valid result';
};

# JS source map reduce
test_riak {
    my ($client, $bucket_name) = @_;
    my $bucket = $client->bucket($bucket_name);
    my $obj    = $bucket->new_object('foo', [2])->store;
    $obj = $bucket->new_object('bar', [3])->store;
    $bucket->new_object('baz', [4])->store;
    my $result =
      $client->add($bucket_name, "foo")->add($bucket_name, "bar")
      ->add($bucket_name, "baz")->map("function (v) { return [1]; }")
      ->reduce("function (v) { return [v.length]; }")->run;
    is $result->[0], 3, "success map reduce";
};

# JS named map reduce
test_riak {
    my ($client, $bucket_name) = @_;
    my $bucket = $client->bucket($bucket_name);
    my $obj    = $bucket->new_object("foo", [2])->store;
    $obj = $bucket->new_object("bar", [3])->store;
    $obj = $bucket->new_object("baz", [4])->store;
    my $result =
      $client->add($bucket_name, "foo")->add($bucket_name, "bar")
      ->add($bucket_name, "baz")->map("Riak.mapValuesJson")
      ->reduce("Riak.reduceSum")->run();
    ok $result->[0];
};

# JS bucket map reduce
test_riak {
    my ($client, $bucket_name) = @_;
    my $bucket = $client->bucket("bucket_".int(rand(10)));
    $bucket->new_object("foo", [2])->store;
    $bucket->new_object("bar", [3])->store;
    $bucket->new_object("baz", [4])->store;
    my $result =
      $client->add($bucket->name)->map("Riak.mapValuesJson")
      ->reduce("Riak.reduceSum")->run;
    ok $result->[0];
};

# JS map reduce from object
test_riak {
    my ($client, $bucket_name) = @_;
    my $bucket = $client->bucket($bucket_name);
    $bucket->new_object("foo", [2])->store;
    my $obj = $bucket->get("foo");
    my $result = $obj->map("Riak.mapValuesJson")->run;
    is_deeply $result->[0], [2], 'valid content';
};

