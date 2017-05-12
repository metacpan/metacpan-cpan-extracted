#!perl
use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('PONAPI::DAO');
    use_ok('Test::PONAPI::Repository::MockDB');
    use_ok('Test::PONAPI::Repository::MockDB::Loader');
}

my $repository = Test::PONAPI::Repository::MockDB->new;
isa_ok($repository, 'Test::PONAPI::Repository::MockDB');

my $dao = PONAPI::DAO->new( version => '1.0', repository => $repository );
isa_ok($dao, 'PONAPI::DAO');

my %TYPE_ID = ( type => 'articles', id => 2 );

subtest '... fields' => sub {

    subtest '... fields set for type' => sub {

        my @ret = $dao->retrieve( %TYPE_ID, fields => { articles => [qw<title body>] } );
        my $doc = $ret[2];

        my $data = $doc->{data};
        ok($data, '... the document has a `data` key');
        is(ref $data, 'HASH', '... the document has one resource');

        ok($data->{attributes}, '... the `data` has an `attributes` key');
        is_deeply(
            [ sort keys %{ $data->{attributes} } ],
            [qw<body title>],
            '... `data.attributes` got only the requested fields'
        );

    };

    subtest '... empty fields set for type' => sub {

        my @ret = $dao->retrieve( %TYPE_ID, fields => { articles => [] } );
        my $doc = $ret[2];

        my $data = $doc->{data};
        ok($data, '... the document has a `data` key');
        is(ref $data, 'HASH', '... the document has one resource');

        ok(!exists $data->{attributes}, "... the `data` doesn't have an `attributes` key");

    };

    subtest '... empty fields set for relationship type' => sub {

        my @ret = $dao->retrieve( %TYPE_ID, fields => { people => [] } );
        my $doc = $ret[2];

        my $data = $doc->{data};
        ok($data, '... the document has a `data` key');
        is(ref $data, 'HASH', '... the document has one resource');

        ok($data->{relationships}, '... the `data` has a `relationships` key');
        ok(exists $data->{relationships}{comments}, "... `data.relationships` has a `comments` key");
        ok(!exists $data->{relationships}{authors}, "... `data.relationships` doesn't have an `authors` key");

    };

    subtest '... fields set for an included type' => sub {

        my @ret = $dao->retrieve( %TYPE_ID, include => [qw<authors>], fields => { people => [qw<name age>] } );
        my $doc = $ret[2];

        my $included = $doc->{included};
        ok($included, '... the document has an `included` key');
        is(ref $included, 'ARRAY', '... `included` is an array');
        ok(@{$included} == 1, '... `included` has one resource');
        is(ref $included->[0], 'HASH', '... included resource is an object');
        ok(exists $included->[0]{attributes}, '... included resource has an `attributes` key');
        is(ref $included->[0]{attributes}, 'HASH', '... the `attributes` points to a hash');
        is_deeply(
            [ sort keys %{ $included->[0]{attributes} } ],
            [qw< age name >],
            '... the included resource has only the requested fields'
        );

    };

    subtest '... empty fields set for an included type' => sub {

        my @ret = $dao->retrieve( %TYPE_ID, include => [qw<authors>], fields => { people => [] } );
        my $doc = $ret[2];

        ok(!exists $doc->{included}, "... the document doesn't have an `included` key");

    };

};

subtest '... filter' => sub {

    subtest '... filter with no keys or values' => sub {

        my @ret = $dao->retrieve_all( type => 'articles', filter => {} );
        my $doc = $ret[2];

        my $errors = $doc->{errors};
        ok($errors, '... the document has an `errors` key');
        is(ref $errors, 'ARRAY', "and it's an array-ref");
        is(@$errors, 1, '... we have one error');
        is_deeply(
            $errors->[0],
            {
                detail => "`filter` is missing values",
                status => 400
            },
            '... and it contains what we expected'
        );
    };

    subtest '... filter key with no values' => sub {

        my @ret = $dao->retrieve_all( type => 'articles', filter => { id => [] } );
        my $doc = $ret[2];

        my $data = $doc->{data};
        ok($data, '... the document has a `data` key');
        is(ref $data, 'ARRAY', '... the document has multiple resources');
        is(@$data, 0, '... but is an empty list');
    };

    subtest '... filter for specific ids' => sub {

        my @ret = $dao->retrieve_all( type => 'articles', filter => { id => [3,2] } );
        my $doc = $ret[2];

        my $data = $doc->{data};
        ok($data, '... the document has a `data` key');
        is(ref $data, 'ARRAY', '... the document has multiple resources');
        is(@$data, 2, '... exactly 2 of them');
        is_deeply(
            [ sort { $a <=> $b } map { $_->{id} } @$data ],
            [ 2, 3 ],
            'and we have the correct ids'
        )

    };

};

subtest '... include' => sub {

    subtest '... include with no values' => sub {

        my @ret = $dao->retrieve( type => 'articles', id => 2, include => [] );
        my $doc = $ret[2];

        my $errors = $doc->{errors};
        ok($errors, '... the document has an `errors` key');
        is(ref $errors, 'ARRAY', "and it's an array-ref");
        is(@$errors, 1, '... we have one error');
        is_deeply(
            $errors->[0],
            {
                detail => "`include` is missing values",
                status => 400
            },
            '... and it contains what we expected'
        );
    };

    subtest '... filter for specific ids' => sub {

        my @ret = $dao->retrieve( type => 'articles', id => 2, include => [qw< comments >] );
        my $doc = $ret[2];

        my $included = $doc->{included};
        ok($included, '... the document has an `included` key');
        is(ref $included, 'ARRAY', '... `included` value is an array-ref ');
        is(@$included, 2, '... of exactly 2 elements');
        is_deeply(
            [ sort { $a <=> $b } map { $_->{id} } @$included ],
            [ 5, 12 ],
            'and we have the correct ids'
        )

    };


};

subtest '... sort' => sub {

    subtest '... sort with no values' => sub {

        my @ret = $dao->retrieve_all( type => 'articles', sort => [] );
        my $doc = $ret[2];

        my $errors = $doc->{errors};
        ok($errors, '... the document has an `errors` key');
        is(ref $errors, 'ARRAY', "and it's an array-ref");
        is(@$errors, 1, '... we have one error');
        is_deeply(
             $errors->[0],
             {
                 detail => "`sort` is missing values",
                 status => 400
             },
             '... and it contains what we expected'
         );
    };

    subtest '... sort on `id`' => sub {

        my @ret = $dao->retrieve_all( type => 'articles', sort => [qw< -id >] );
        my $doc = $ret[2];

        my $data = $doc->{data};
        ok($data, '... the document has an `data` key');
        is(ref $data, 'ARRAY', '... `data` value is an array-ref ');

        my @ids = map { $_->{id} } @$data;
        is(@$data, 3, '... of exactly 3 elements');
        is_deeply(
            \@ids,
            [ 3, 2, 1 ],
            'and we have all the ids in the correct order'
        )

    };

};

subtest '... page' => sub {

    subtest '... page with no values' => sub {

        my @ret = $dao->retrieve_all( type => 'articles', page => {} );
        my $doc = $ret[2];

        my $errors = $doc->{errors};
        ok($errors, '... the document has an `errors` key');
        is(ref $errors, 'ARRAY', "and it's an array-ref");
        is(@$errors, 1, '... we have one error');
        is_deeply(
             $errors->[0],
             {
                 detail => "`page` is missing values",
                 status => 400
             },
             '... and it contains what we expected'
         );
    };

    subtest '... page with limit == 2' => sub {

        my @ret = $dao->retrieve_all( req_path => '/articles', type => 'articles', page => { limit => 2 } );
        my $doc = $ret[2];

        my $data = $doc->{data};
        ok($data, '... the document has an `data` key');
        is(ref $data, 'ARRAY', '... `data` value is an array-ref ');
        is(@$data, 2, '... of exactly 2 elements');

        my $links = $doc->{links};
        ok($links, '... the document has an `links` key');
        is(ref $links, 'HASH', '... `links` value is a hash-ref ');
        is_deeply(
            [ sort keys %$links ],
            [qw< first next self >],
            '... `links` has all expected keys'
        );
        ok(scalar(grep /^\/articles/, values %$links)==3, '... all links have the correct base');
        ok(scalar(grep /page%5Blimit%5D=2/, values %$links)==3,  '... all links contain the correct `limit`');
        ok($links->{first} =~ /page%5Boffset%5D=0/, '... `first` link points to offset=0');
        ok($links->{next}  =~ /page%5Boffset%5D=2/, '... `next`  link points to offset=2');
        ok($links->{self}  =~ /page%5Boffset%5D=0/, '... `self`  link points to offset=0');

    };

    subtest '... page with limit == 2, offset = 1' => sub {

        my @ret = $dao->retrieve_all( req_path => '/articles', type => 'articles', page => { limit => 2, offset => 1 } );
        my $doc = $ret[2];

        my $data = $doc->{data};
        ok($data, '... the document has an `data` key');
        is(ref $data, 'ARRAY', '... `data` value is an array-ref ');
        is(@$data, 2, '... of exactly 2 elements');

        my $links = $doc->{links};
        ok($links, '... the document has an `links` key');
        is(ref $links, 'HASH', '... `links` value is a hash-ref ');
        is_deeply(
            [ sort keys %$links ],
            [qw< first next self >],
            '... `links` has all expected keys'
        );
        ok(scalar(grep /^\/articles/, values %$links)==3, '... all links have the correct base');
        ok(scalar(grep /page%5Blimit%5D=2/, values %$links)==3,  '... all links contain the correct `limit`');
        ok($links->{first} =~ /page%5Boffset%5D=0/, '... `first` link points to offset=0');
        ok($links->{next}  =~ /page%5Boffset%5D=3/, '... `next`  link points to offset=3');
        ok($links->{self}  =~ /page%5Boffset%5D=1/, '... `self`  link points to offset=1');

    };

};

done_testing;
