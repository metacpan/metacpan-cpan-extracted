use v5.44;

use Test2::V0 -no_srand => 1;
use Test2::Tools::Subtest 'subtest_buffered';

use Scalar::ValueTags::LineageTracking;
use Scalar::ValueTags qw( get_value_tags add_value_tag );

subtest_buffered constructor => sub {

    my $lt;
    like(
        dies {
            $lt =
              Scalar::ValueTags::LineageTracking->new( tag_type => 'invalid' )
        },
        qr/Invalid tag_type/,
        'instantiation failure: invalid tag_type'
    );

    for my $tag_type ( undef, 'string', 'ref' ) {
        my $expected_tag_type = $tag_type // 'string';

        ok(
            lives {
                $lt = Scalar::ValueTags::LineageTracking->new(
                    $tag_type ? ( tag_type => $tag_type ) : () )
            },
            '->new with ' . ( $tag_type // 'undef' ) . ' tag_type should live',
        );

        is( $lt->tag_type, $expected_tag_type,
            "->tag_type should be '$expected_tag_type'" );
    }
};

sub _data_tracking_ok ( $tag_type, @sources ) {
    my $lt;
    ok(
        lives {
            $lt = Scalar::ValueTags::LineageTracking->new(
                $tag_type ? ( tag_type => $tag_type ) : () )
        }
    );

    subtest_buffered get_and_set_data_sources => sub {
        my $var = 9;

        is( $lt->get_data_sources( \$var ),
            [], 'var without data sources should return empty arrayref' );

        # default tag_type is string
        my $expected_type =
          ( $tag_type // 'string' ) eq 'ref' ? 'unblessed ref' : 'string';

        # blessed object should fail
        like(
            dies { $lt->set_data_sources( \$var, [ $lt, $sources[0] ] ) },
            qr/invalid data_source: must be $expected_type/,
            'set_data_sources with invalid source type should die'
        );

        ok(
            lives {
                $lt->set_data_sources( \$var, [ $sources[0], $sources[1] ] )
            },
            'set_data_sources with valid source types should live'
        );

        is(
            $lt->get_data_sources( \$var ),
            bag { item $sources[0]; item $sources[1]; end(); },
            'get_data_sources should return data sources'
        );

        my $prev_data_sources;
        ok(
            lives {
                $prev_data_sources =
                  $lt->set_data_sources( \$var, [ $sources[1] ] )
            },
            'set_data_sources replacing data sources should live'
        );

        is(
            $lt->get_data_sources( \$var ),
            [ $sources[1] ],
            'set_data_sources should replace previous data sources'
        );

        is(
            $prev_data_sources,
            bag { item $sources[0]; item $sources[1]; end(); },
            'set_data_sources should return previous data sources',
        );
    };

    subtest_buffered add_data_sources => sub {
        my $var;

        $lt->set_data_sources( \$var, [ $sources[0] ] );

        ok(
            lives { $lt->add_data_sources( \$var, [ @sources[ 1 .. 2 ] ] ) },
            'add_data_sources should live',
        );

        is(
            $lt->get_data_sources( \$var ),
            bag { item $sources[0]; item $sources[1]; item $sources[2]; end(); }
            ,
            'add_data_sources should add data sources to existing sources',
        );
    };

    subtest_buffered clear_data_sources => sub {
        my $var;

        $lt->set_data_sources( \$var, [ @sources[ 0 .. 1 ] ] );

        my $prev_data_sources;
        ok(
            lives { $prev_data_sources = $lt->clear_data_sources( \$var ) },
            'clear_data_sources should live',
        );

        is(
            $lt->get_data_sources( \$var ),
            [], 'clear_data_sources should clear data sources',
        );
        is(
            $prev_data_sources,
            bag { item $sources[0]; item $sources[1]; end(); },
            'clear_data_sources should return previous data sources',
        );
    };

    subtest_buffered data_source_propagation => sub {
        my $var_0 = 9;
        my $var_1 = 23;
        my $var_2 = 19;

        $lt->set_data_sources( \$var_0, [ $sources[0] ] );
        $lt->set_data_sources( \$var_1, [ $sources[1] ] );
        $lt->set_data_sources( \$var_2, [ $sources[0] ] );    # duplicate source

        my $sum = $var_0 + $var_1 + $var_2;

        is(
            $lt->get_data_sources( \$sum ),
            bag { item $sources[0]; item $sources[1]; end(); },
            'unique data sources should propagate across addition',
        );

        # JIC
        is( $sum, $var_0 + $var_1 + $var_2, 'sum should be as expected' );
    };
}

subtest_buffered string_tag_type => sub {
    _data_tracking_ok( 'string', 'foo', 'bar', 'baz' );
};

subtest_buffered array_tag_type => sub {
    _data_tracking_ok(
        'ref',
        { this    => 3,     that => 4 },
        { first   => 'red', last => 'green' },
        { silence => 'foo' }
    );
};

done_testing();
