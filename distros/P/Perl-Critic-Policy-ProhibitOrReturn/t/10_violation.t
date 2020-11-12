use Test2::V0;
use Perl::Critic;
use Perl::Critic::Policy::ProhibitOrReturn;

my @testcases = (
    {
        description => 'single violation',
        filename    => 't/data/single.pl',
        expected    => array {
            item object {
                call description   => '`or return` in source file';
                call line_number   => 4;
                call column_number => 5;
            };
            end;
        },
    },
    {
        description => 'multi violation',
        filename    => 't/data/multi.pl',
        expected    => array {
            item object {
                call description   => '`or return` in source file';
                call line_number   => 4;
                call column_number => 5;
            };
            item object {
                call description   => '`or return` in source file';
                call line_number   => 5;
                call column_number => 5;
            };
            end;
        },
    },
);

for my $testcase (@testcases) {
    my $code = do {
        open my $fh, '<', $testcase->{filename} or die "Cannot open $testcase->{filename}: $!";
        local $/;
        <$fh>;
    };
    my $critic = Perl::Critic->new(
        '-single-policy' => 'ProhibitOrReturn',
    );
    my @violations = $critic->critique( \$code );

    is \@violations, $testcase->{expected}, $testcase->{description};
}

done_testing;
