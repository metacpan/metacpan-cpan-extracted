use Test2::V0;
use Perl::Critic;
use Perl::Critic::Policy::ProhibitOrReturn;

my @testcases = (
    {
        description => 'no violation',
        filename    => 't/data/pass.pl',
        expected    => [],
    },
    {
        description => 'only `return` statement',
        filename    => 't/data/only_return.pl',
        expected    => [],
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
