use v5.44;

use Test2::V0 -no_srand => 1;
use Test2::Tools::Subtest 'subtest_buffered';

use Scalar::ValueTags::LineageTracking;

subtest_buffered failures => sub {
    my $lt;
    like(
        dies {
            $lt = Scalar::ValueTags::LineageTracking->new( tag_type => 'invalid' )
        },
        qr/Invalid tag_type/,
        'instantiation failure: invalid tag_type'
    );
};

sub _data_tracking_ok ( $tag_type, $data_source_1, $data_source_2 ) {
    my $lt;
    ok(
        lives {
            $lt = Scalar::ValueTags::LineageTracking->new(
                $tag_type ? ( tag_type => $tag_type ) : () )
        }
    );

    my $var_1 = 9;

    is( $lt->get_data_sources( \$var_1 ),
        [], 'var without data sources should return empty source set' );

    # default tag_type is string
    my $expected_type =
      ( $tag_type // 'string' ) eq 'ref' ? 'unblessed ref' : 'string';

    # blessed object should fail
    like(
        dies { $lt->set_data_source( \$var_1, $lt ) },
        qr/invalid data_source: must be $expected_type/,
        'set_data_source with invalid source type should die'
    );

    ok( lives { $lt->set_data_source( \$var_1, $data_source_1 ) },
        'set_data_source on var_1 should live' );

    is( $lt->get_data_sources( \$var_1 ),
        [$data_source_1], 'get_data_sources for var_1 should return data source 1' );

    is( $var_1, 9, 'var_1 value should be unchanged' );

    my $var_2 = 99;
    ok( lives { $lt->set_data_source( \$var_2, $data_source_2 ) },
        'set_data_source on var_2 should live' );

    my $sum = $var_1 + $var_2;
    is(
        $lt->get_data_sources( \$sum ),
        bag { item $data_source_1; item $data_source_2; end(); },
        'get_data_sources for sum should return both data sources',
    );
    is( $sum, $var_1 + $var_2, 'value of sum should be correct' );    # JIC

    is( $lt->get_and_clear_data_sources( \$var_1 ),
        [$data_source_1],
        'get_and_clear_data_sources for var_1 should return data source 1' );
    is( $lt->get_data_sources( \$var_1 ),
        [], 'get_and_clear_data_sources for var_1 should clear data sources' );

    ok(
        lives { $lt->clear_data_sources( \$var_2 ) },
        'clear_data_sources for var_2 should live'
    );
    is( $lt->get_data_sources( \$var_2 ),
        [], 'get_and_clear_data_sources for var_2 should clear data sources' );

    ok(
        lives { $lt->set_data_source( \$sum, $data_source_1 ) },
        'set_data_source for sum should live'
    );
    is( $lt->get_data_sources( \$sum ),
        [$data_source_1],
        'set_data_source should replace existing sources with new source',
    );
}

subtest_buffered default_tag_type => sub {
    _data_tracking_ok( undef, 'foo', 'bar' );
};

subtest_buffered string_tag_type => sub {
    _data_tracking_ok( 'string', 'foo', 'bar' );
};

subtest_buffered array_tag_type => sub {
    _data_tracking_ok( 'ref', { this => 3, that => 4 }, { first => 'red', last => 'green' } );
};

done_testing();
