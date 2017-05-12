#!/usr/bin/perl

use Test::More;

BEGIN {
    use_ok( 'Query::Abstract' ) || print "Bail out!\n";
}

my $fm = Query::Abstract->new( driver => ['ArrayOfHashes'] );
isa_ok($fm, 'Query::Abstract', 'Should create Query::Abstract instance');

my @objects = (
    {id => 1, fname => 'Ivan',  lname => 'Pupkin'},
    {id => 2, fname => 'Ivan',  lname => 'Ivanov'},
    {id => 3, fname => 'Taras', lname => 'Shevchenko'},
    {id => 4, fname => 'Taras', lname => 'Leleka'},
    {id => 5, fname => 'Taras', lname => 'Leleka'},
);

subtest 'Simplest "eq" query' => sub {
    my $query_sub = $fm->convert_query( [ fname => { eq => 'ivan' } ] );
    ok(ref($query_sub) eq 'CODE', 'Query should be a coderef');

    my $queryed = $query_sub->(\@objects);
    is(scalar(@$queryed), 2, 'Should return 2 hashes with fname eq "ivan"' );
    is($queryed->[0]{id}, 1, 'Hash should be with id=1');
    is($queryed->[1]{id}, 2, 'Hash should be with id=2');
};

subtest 'Simplest "eq" query with DESC sort ' => sub {
    my $query_sub = $fm->convert_query( where => [ fname => { eq => 'ivan' } ], sort_by => 'id DESC' );
    ok(ref($query_sub) eq 'CODE', 'Query should be a coderef');

    my $queryed = $query_sub->(\@objects);
    is(scalar(@$queryed), 2, 'Should return 2 hashes with fname eq "ivan"' );
    is($queryed->[0]{id}, 2, 'Hash should be with id=2');
    is($queryed->[1]{id}, 1, 'Hash should be with id=1');
};

subtest 'Simplest "like" query' => sub {
    my $query_sub = $fm->convert_query( where => [ lname => { like => 'iva%' } ] );
    ok(ref($query_sub) eq 'CODE', 'Query should be coderef');

    my $queryed = $query_sub->(\@objects);
    is(scalar(@$queryed), 1, 'Should return only one hash with lname like "iva%"' );
    is( $queryed->[0]{id}, 2, 'Hash should be with id=2' );
};


subtest 'Complex query' => sub {
    my $query_sub = $fm->convert_query( [
        fname => { eq => 'taras' },
        id => {'<' => 5},
        lname => ['Leleka', 'Ivanov']
    ]);

    ok(ref($query_sub) eq 'CODE', 'Query should be coderef');

    my $queryed = $query_sub->(\@objects);
    is(scalar(@$queryed), 1, 'Should return only one hash' );
    is( $queryed->[0]{id}, 4, 'Hash should be with id=4' );
};

done_testing();