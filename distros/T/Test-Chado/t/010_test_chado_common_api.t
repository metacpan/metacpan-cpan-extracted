use Test::Tester;
use Test::More qw/no_plan/;
use Test::Exception;
use Test::Chado qw(:schema);
use Test::Chado::Common;


Test::Chado->ignore_tc_env(1);

subtest 'features of has_cv method' => sub {
    my $schema = chado_schema( load_fixture => 1 );
    dies_ok { has_cv() } 'should die without schema';
    dies_ok { has_cv($schema) } 'should die without passing cv name';

    my $desc = 'should have existing cv name';
    check_test(
        sub { has_cv $schema, 'sequence', $desc },
        {   ok   => 1,
            name => $desc
        },
        $desc
    );

    $desc = 'should fail with non existing cv name';
    check_test( sub { has_cv $schema, 'fake', $desc },
        { ok => 0, name => $desc }, $desc );
    drop_schema();
};

subtest 'features of has_cvterm method' => sub {
    my $schema = chado_schema( load_fixture => 1 );
    dies_ok { has_cvterm() } 'should die without schema';
    dies_ok { has_cvterm($schema) } 'should die without passing cvterm name';

    my $desc = 'should have existing cvterm name';
    check_test(
        sub { has_cvterm $schema, 'gene', $desc },
        {   ok   => 1,
            name => $desc
        },
        $desc
    );

    $desc = 'should fail with non existing cvterm name';
    check_test( sub { has_cvterm $schema, 'fake', $desc },
        { ok => 0, name => $desc }, $desc );
    drop_schema();

};

subtest 'features of has_dbxref method' => sub {
    my $schema = chado_schema( load_fixture => 1 );
    dies_ok { has_dbxref() } 'should die without schema';
    dies_ok { has_dbxref($schema) } 'should die without passing dbxref';

    my $desc = 'should have existing dbxref';
    check_test(
        sub { has_dbxref $schema, 'OBO_REL:has_participant', $desc },
        {   ok   => 1,
            name => $desc
        },
        $desc
    );

    $desc = 'should fail with non existing dbxref';
    check_test( sub { has_dbxref $schema, 'fake', $desc },
        { ok => 0, name => $desc }, $desc );
    drop_schema();

};

subtest 'features of has_feature method' => sub {
    my $schema = chado_schema( load_fixture => 1 );
    my $organism = $schema->resultset('Organism')
        ->search( { common_name => 'human' }, { rows => 1 } )->first;
    $schema->resultset('Feature')->create(
        {   uniquename  => 'test-gene',
            organism_id => $organism->organism_id,
            type_id =>
                $schema->resultset('Cvterm')->find( { name => 'gene' } )
                ->cvterm_id
        }
    );

    dies_ok { has_feature() } 'should die without schema';
    dies_ok { has_feature($schema) } 'should die without passing feature name';

    my $desc = 'should have existing feature';
    check_test(
        sub { has_feature $schema, 'test-gene', $desc },
        {   ok   => 1,
            name => $desc
        },
        $desc
    );

    $desc = 'should fail with non existing feature';
    check_test( sub { has_feature $schema, 'fake', $desc },
        { ok => 0, name => $desc }, $desc );
    drop_schema();
};

subtest 'features of has_featureloc method' => sub {
    my $schema = chado_schema( load_fixture => 1 );
    my $organism = $schema->resultset('Organism')
        ->search( { common_name => 'human' }, { rows => 1 } )->first;
    $schema->resultset('Feature')->create(
        {   uniquename  => 'test-transcript',
            organism_id => $organism->organism_id,
            type_id =>
                $schema->resultset('Cvterm')->find( { name => 'mRNA' } )
                ->cvterm_id,
            featureloc_features => [
                {
                    fmin => 1,
                    fmax => 234
                }
            ]
        }
    );

    dies_ok { has_featureloc() } 'should die without schema';
    dies_ok { has_featureloc($schema) } 'should die without passing feature name';

    my $desc = 'should have existing feature with location';
    check_test(
        sub { has_featureloc $schema, 'test-transcript', $desc },
        {   ok   => 1,
            name => $desc
        },
        $desc
    );

    $desc = 'should fail with non existing feature';
    check_test( sub { has_featureloc $schema, 'fake', $desc },
        { ok => 0, name => $desc }, $desc );
    drop_schema();
};


