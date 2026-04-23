#! perl

use Test2::V0;
use Test2::Tools::Exports;
use JSON::PP qw(decode_json);
use Path::Tiny;
use PGPLOTx::Constants ();

## no critic ( NoStrict StringyEval )

my $constants_json = path( 't/constants.json' );

my $documented = decode_json( $constants_json->slurp );

for my $cat ( sort keys %{$documented} ) {
    subtest "Category: $cat" => sub {
        my $names_sub        = "${cat}_NAMES";
        my $tag              = q{-} . lc $cat;
        my $coerce_tag       = lc $cat;
        my @documented_names = @{ $documented->{$cat} };

        subtest 'import functions individually' => sub {
            my $pkg = "My::Test::Helpers::$cat";

            {
                no strict 'refs';
                eval <<"EOT" or die $@;
                package $pkg;
                use Test2::V0;
                use Test2::Tools::Exports;
                use PGPLOTx::Constants qw( $cat $names_sub @documented_names );

                # ensure imports
                subtest 'helper funcs' => sub {
                    imported_ok( qw( $cat $names_sub ) );
                    is( [ $names_sub()],
                        bag { item \$_ for qw( @documented_names ); end; },
                        '$names_sub values' );

                    # can't directly compare values (well could, but
                    # that would mean embedding them here), so check count
                    is( 0+@{[$cat]}, @{[ 0+ @documented_names]} , "$cat returns expected count" );

                    };

                subtest 'constants' => sub {
                    imported_ok( qw( @documented_names ) );
                };

                1;
EOT
            }

        };

        subtest "Tag import: $tag" => sub {
            my $pkg = "My::Test::Tag::$cat";

            {
                no strict 'refs';
                eval << "EOT" or die $@;
                package $pkg;
                use Test2::V0;
                use Test2::Tools::Exports;
                use PGPLOTx::Constants '$tag';

                subtest 'constants' => sub {
                    imported_ok( qw( @documented_names ) );
                };

                1;
EOT
            }
        };

        subtest 'ui helper api' => sub {
            my %expected;

            for my $name ( @documented_names ) {
                my $value = PGPLOTx::Constants->can( $name )->();
                $expected{$name} = $value;
                $expected{ lc $name } = $value;

                ( my $dashed = $name ) =~ s/_/-/g;
                $expected{$dashed} = $value;
                $expected{ lc $dashed } = $value;
            }

            is(
                [ PGPLOTx::Constants::list_constants( $coerce_tag ) ],
                bag { item $_ for keys %expected; end; },
                "list_constants($coerce_tag) returns documented names and aliases",
            );

            for my $label ( sort keys %expected ) {
                is(
                    PGPLOTx::Constants::coerce_constant( $coerce_tag, $label ),
                    $expected{$label}, "coerce_constant($coerce_tag, $label) returns expected value",
                );
            }

            like(
                dies { PGPLOTx::Constants::list_constants( 'not_a_tag' ) },
                qr/\Aunknown constant tag 'not_a_tag'/,
                'list_constants croaks for an unknown tag',
            );

            like(
                dies { PGPLOTx::Constants::coerce_constant( $coerce_tag, 'not-a-label' ) },
                qr/\Aunknown constant '\Q$coerce_tag:not-a-label\E'/,
                'coerce_constant croaks for an unknown label',
            );
        };
    };
}

subtest 'global as => lc' => sub {
    {
        package My::Test::GlobalAs;
        use Test2::V0;
        use Test2::Tools::Exports;
        use PGPLOTx::Constants 'COLORS_NAMES';
        use PGPLOTx::Constants { as => 'lc' }, '-colors';

        subtest 'constants' => sub {
            imported_ok( map { lc } COLORS_NAMES );
        };
    }
};

subtest 'tag -as => lc' => sub {
    {
        package My::Test::SymbolAs;
        use Test2::V0;
        use Test2::Tools::Exports;
        use PGPLOTx::Constants 'COLORS_NAMES';
        use PGPLOTx::Constants -colors, { -as => 'lc' };

        subtest 'constants' => sub {
            imported_ok( map { lc } COLORS_NAMES );
        };
    }
};

done_testing;
