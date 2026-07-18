use strict;
use warnings;

use Perl::Critic::TestUtils qw( pcritique_with_violations );
use Test::More;

my $policy = 'ErrorHandling::RequireReturnFromEval';

HAPPY_PATH: {
    note( 'happy path - eval with explicit return' );

    my $code = <<'EOF';
my $x = eval { return some_func() };
EOF

    my @violations = pcritique_with_violations( $policy, \$code );
    is( scalar @violations, 0, 'no violation for eval with return' );
}

HAPPY_PATH_MULTI_STATEMENT: {
    note( 'happy path - eval with multiple returns' );

    my $code = <<'EOF';
my $x = eval {
    my $y = 1;
    return $y;
};
EOF

    my @violations = pcritique_with_violations( $policy, \$code );
    is( scalar @violations, 0, 'no violation for eval with return after statements' );
}

VIOLATION_NO_RETURN: {
    note( 'violation - eval without return' );

    my $code = <<'EOF';
my $x = eval { some_func() };
EOF

    my @violations = pcritique_with_violations( $policy, \$code );
    is( scalar @violations, 1, 'violation for eval without return' );
}

VIOLATION_NO_RETURN_MULTI_STATEMENT: {
    note( 'violation - eval with multiple statements, no return' );

    my $code = <<'EOF';
my $x = eval {
    my $y = some_func();
    $y + 1;
};
EOF

    my @violations = pcritique_with_violations( $policy, \$code );
    is( scalar @violations, 1, 'violation for eval with multiple statements and no return' );
}

NO_VIOLATION_STRING_EVAL: {
    note( 'no violation - string eval is not affected' );

    my $code = <<'EOF';
my $x = eval "some_func()";
EOF

    my @violations = pcritique_with_violations( $policy, \$code );
    is( scalar @violations, 0, 'no violation for string eval' );
}

VIOLATION_VOID_EVAL: {
    note( 'violation - void eval (no return)' );

    my $code = <<'EOF';
eval { some_func() };
EOF

    my @violations = pcritique_with_violations( $policy, \$code );
    is( scalar @violations, 1, 'violation for void eval without return' );
}

NO_VIOLATION_EMPTY_EVAL: {
    note( 'no violation - empty eval block' );

    my $code = <<'EOF';
my $x = eval { };
EOF

    my @violations = pcritique_with_violations( $policy, \$code );
    is( scalar @violations, 0, 'no violation for empty eval block' );
}

done_testing();
