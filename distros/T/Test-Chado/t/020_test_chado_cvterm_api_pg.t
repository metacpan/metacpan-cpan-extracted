use Test::Tester;
use Test::More qw/no_plan/;
use Test::Exception;
use File::ShareDir qw/module_file/;
use Module::Load qw/load/;

SKIP: {
    skip 'Environment variable TC_DSN is not set',
        if not defined $ENV{TC_DSN};
    eval { require DBD::Pg };
    skip 'DBD::Pg is needed to run this test' if $@;

    load Test::Chado,         ':schema';
    load Test::Chado::Cvterm, ':all';

    my $preset = module_file( 'Test::Chado', 'eco.tar.bz2' );

    subtest 'features of count api' => sub {
        my $schema = chado_schema( custom_fixture => $preset );
        dies_ok { count_cvterm_ok() } 'should die without schema';
        dies_ok { count_cvterm_ok($schema) } 'should die without parameters';
        dies_ok { count_cvterm_ok( $schema, { 'cv' => 'cv_property' } ) }
        'should die without all arguments';

        my $desc = 'should have 294 cvterms';
        check_test(
            sub {
                count_cvterm_ok( $schema, { 'cv' => 'eco', 'count' => 294 },
                    $desc );
            },
            {   ok   => 1,
                name => $desc
            },
            $desc
        );

        $desc = 'should have 3 obsolete cvterms';
        check_test(
            sub {
                count_obsolete_cvterm_ok( $schema,
                    { 'cv' => 'eco', 'count' => 3 }, $desc );
            },
            {   ok   => 1,
                name => $desc
            },
            $desc
        );

        $desc = 'should have 1 relationship cvterm';
        check_test(
            sub {
                count_relationship_cvterm_ok( $schema,
                    { 'cv' => 'eco', 'count' => 1 }, $desc );
            },
            {   ok   => 1,
                name => $desc
            },
            $desc
        );

        $desc = 'should have 213 synonyms';
        check_test(
            sub {
                count_synonym_ok( $schema, { 'cv' => 'eco', 'count' => 213 },
                    $desc );
            },
            {   ok   => 1,
                name => $desc
            },
            $desc
        );

        $desc = 'should have 7 alt_ids';
        check_test(
            sub {
                count_alt_id_ok( $schema,
                    { 'count' => 7, db => 'ECO' }, $desc );
            },
            {   ok   => 1,
                name => $desc
            },
            $desc
        );

        $desc = 'should have 68 comments';
        check_test(
            sub {
                count_comment_ok( $schema, { 'cv' => 'eco', 'count' => 68 },
                    $desc );
            },
            {   ok   => 1,
                name => $desc
            },
            $desc
        );

        $desc = 'should have 14 subjects';
        check_test(
            sub {
                count_subject_ok(
                    $schema,
                    {   'cv'           => 'eco',
                        'count'        => 14,
                        object         => 'direct assay evidence',
                        'relationship' => 'is_a'
                    },
                    $desc
                );
            },
            {   ok   => 1,
                name => $desc
            },
            $desc
        );

        $desc = 'should have 58 subjects';
        check_test(
            sub {
                count_subject_ok(
                    $schema,
                    {   'cv'           => 'eco',
                        'count'        => 58,
                        object         => 'manual assertion',
                        'relationship' => 'used_in'
                    },
                    $desc
                );
            },
            {   ok   => 1,
                name => $desc
            },
            $desc
        );

        $desc = 'should have 3 objects';
        my $subject
            = 'non-traceable author statement used in manual assertion';
        check_test(
            sub {
                count_object_ok( $schema,
                    { 'cv' => 'eco', 'count' => 3, 'subject' => $subject },
                    $desc );
            },
            {   ok   => 1,
                name => $desc
            },
            $desc
        );

        $desc = 'should have 1 object with used_in relationship';
        check_test(
            sub {
                count_object_ok(
                    $schema,
                    {   'cv'         => 'eco',
                        'count'      => 1,
                        'subject'    => $subject,
                        relationship => 'used_in'
                    },
                    $desc
                );
            },
            {   ok   => 1,
                name => $desc
            },
            $desc
        );
        drop_schema();
    };

    subtest 'features of checking api' => sub {
        my $schema = chado_schema( custom_fixture => $preset );

        my $desc = 'should have synonym';
        check_test(
            sub {
                has_synonym(
                    $schema,
                    {   'cv'      => 'eco',
                        'term'    => 'similarity evidence',
                        'synonym' => 'inferred from similarity'
                    },
                    $desc
                );
            },
            {   ok   => 1,
                name => $desc
            },
            $desc
        );

        $desc = 'should have obsolete cvterm';
        check_test(
            sub {
                is_obsolete_cvterm(
                    $schema,
                    {   'cv'   => 'eco',
                        'term' => 'not_recorded'
                    },
                    $desc
                );
            },
            {   ok   => 1,
                name => $desc
            },
            $desc
        );

        $desc = 'should have alt_id';
        check_test(
            sub {
                has_alt_id(
                    $schema,
                    {   'cv'     => 'eco',
                        'term'   => 'combinatorial evidence',
                        'alt_id' => 'ECO:0000043'
                    },
                    $desc
                );
            },
            {   ok   => 1,
                name => $desc
            },
            $desc
        );

        $desc = 'should have xref';
        check_test(
            sub {
                has_xref(
                    $schema,
                    {   'cv'   => 'eco',
                        'term' => 'evidence used in automatic assertion',
                        'xref' => 'GO_REF:0000023'
                    },
                    $desc
                );
            },
            {   ok   => 1,
                name => $desc
            },
            $desc
        );

        $desc = 'should have comment';
        my $comment
            = 'Genomic cluster analyses include synteny and operon structure.';
        check_test(
            sub {
                has_comment(
                    $schema,
                    {   'cv'      => 'eco',
                        'term'    => 'gene neighbors evidence',
                        'comment' => $comment
                    },
                    $desc
                );
            },
            {   ok   => 1,
                name => $desc
            },
            $desc
        );

        $desc = 'should have a is_a relationship between parent and child';
        check_test(
            sub {
                has_relationship(
                    $schema,
                    {   'subject'      => 'curator inference',
                        'object'       => 'evidence',
                        'relationship' => 'is_a'
                    },
                    $desc
                );
            },
            {   ok   => 1,
                name => $desc
            },
            $desc
        );

        $desc = 'should have a used_in relationship between parent and child';
        check_test(
            sub {
                has_relationship(
                    $schema,
                    {   'subject' =>
                            'genomic microarray evidence used in manual assertion',
                        'object'       => 'manual assertion',
                        'relationship' => 'used_in'
                    },
                    $desc
                );
            },
            {   ok   => 1,
                name => $desc
            },
            $desc
        );


        drop_schema();
    };

}
