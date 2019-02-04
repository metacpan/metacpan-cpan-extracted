use strict;
use warnings;
use Test::More qw(no_plan);
use Env qw($TEST_VERBOSE);
use Data::Dumper;

use_ok 'Perl::Critic::Policy::RegularExpressions::RequireDefault';

require Perl::Critic;
my $critic = Perl::Critic->new(
    '-profile'       => '',
    '-single-policy' => 'RegularExpressions::RequireDefault'
);
{
    my @p = $critic->policies;
    is( scalar @p, 1, 'single policy RegularExpressions::RequireDefault' );

    my $policy = $p[0];
}

foreach my $data (
    [ 1, q{/\d/}, q{Regular expression without "/a" or "/aa" flag} ],
    [ 0, q{/\d/a}, q{} ],
    [ 0, q{/\d/aa}, q{} ],
    )
{
    my ( $want_count, $str, $assertion ) = @{$data};

    my @violations = $critic->critique( \$str );
    foreach (@violations) {
        is( $_->description, $assertion, "violation: $assertion" );
    }
    is( scalar @violations, $want_count, "statement: $str" );
}

{
    my $str = q[
        use re '/a';
        my $digits = 1234;
        if ($digits =~ m/\d/) {
            print "We have digits\n";
        }
    ];

    my @violations = $critic->critique( \$str );

    is( scalar @violations, 0 );
}

{
    my $str = q[
        use re '/aa';
        my $greeting = 'hello world';

        my $greeting =~ s/hello/goodmorning/;
    ];

    my @violations = $critic->critique( \$str );

    is( scalar @violations, 0 );
}

$critic = Perl::Critic->new(
    '-profile'       => 't/example_strict_set.conf',
    '-single-policy' => 'RegularExpressions::RequireDefault'
);

{
    my $str = q[
        my $digits = 1234;
        if ($digits =~ m/\d/a) {
            print "We have digits\n";
        }
    ];

    my @violations = $critic->critique( \$str );

    is( scalar @violations, 1 );
}

{
    my $str = q[
        my $greeting = 'hello world';

        my $greeting =~ s/hello/goodmorning/aa;
    ];

    my @violations = $critic->critique( \$str );

    is( scalar @violations, 0 );
}

{
    my $str = q[
        use re '/a';
        my $digits = 1234;
        if ($digits =~ m/\d/) {
            print "We have digits\n";
        }
    ];

    my @violations = $critic->critique( \$str );

    is( scalar @violations, 1 );
}

{
    my $str = q[
        use re '/aa';
        my $greeting = 'hello world';

        my $greeting =~ s/hello/goodmorning/;
    ];

    my @violations = $critic->critique( \$str );

    is( scalar @violations, 0 );
}

$critic = Perl::Critic->new(
    '-profile'       => 't/example_strict_notset.conf',
    '-single-policy' => 'RegularExpressions::RequireDefault'
);

{
    my $str = q[
        my $digits = 1234;
        if ($digits =~ m/\d/a) {
            print "We have digits\n";
        }
    ];

    my @violations = $critic->critique( \$str );

    is( scalar @violations, 0 );
}

{
    my $str = q[
        my $greeting = 'hello world';

        my $greeting =~ s/hello/goodmorning/aa;
    ];

    my @violations = $critic->critique( \$str );

    is( scalar @violations, 0 );
}

{
    my $str = q[
        use re '/a';
        my $digits = 1234;
        if ($digits =~ m/\d/) {
            print "We have digits\n";
        }
    ];

    my @violations = $critic->critique( \$str );

    is( scalar @violations, 0 );
}

{
    my $str = q[
        use re '/aa';
        my $greeting = 'hello world';

        my $greeting =~ s/hello/goodmorning/;
    ];

    my @violations = $critic->critique( \$str );

    is( scalar @violations, 0 );
}

exit 0;
