
use 5.010;
use Test::More 0.88;
use Test::Deep;

use PPI;
use PPIx::Literal;

my @TESTS = (
    {   code     => q{},
        expected => [],
        name     => '',
    },
    {   code     => q{42},
        expected => [42],
    },
    {   code     => q{"a + b"},
        expected => ["a + b"],
    },
    {   code     => q{'simple'},
        expected => ['simple'],
    },
    {   code     => q{qw(a b c)},
        expected => [qw(a b c)],
    },
    {   code     => q{[]},
        expected => [ [] ],
    },
    {   code     => q{{ -version => '0.3.2'}},
        expected => [ { -version => '0.3.2' } ],
    },
    {   code     => q{(2, 3, 4)},
        expected => [ 2, 3, 4 ],
    },
    {   code     => q{2, 3, 4},
        expected => [ 2, 3, 4 ],
    },

    # basic unknowns
    {   code     => q{$var},
        expected => [ isa('PPIx::Literal::Unknown') ],
        name     => '$var is not a literal',
    },
);

for my $t (@TESTS) {
    my $perl_code = $t->{code};
    my $expected  = $t->{expected};
    my $test      = $t->{name} // ( $t->{code} . ' - converted' );

    my $doc    = PPI::Document->new( \$perl_code );
    my @values = PPIx::Literal->convert($doc);
    cmp_deeply( \@values, $expected, $test );
}

done_testing;
