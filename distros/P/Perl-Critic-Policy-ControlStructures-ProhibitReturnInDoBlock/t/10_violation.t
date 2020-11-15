use Test2::V0;
use Perl::Critic;
use Perl::Critic::Policy::ControlStructures::ProhibitReturnInDoBlock;

my @testcases = (
    {
        description => 'single violation',
        filename    => 't/data/single.pl',
        expected    => array {
            item object {
                call description   => '"return" statement in "do" block';
                call line_number   => 8;
                call column_number => 9;
            };
            end;
        },
    },
    {
        description => 'multiple violation',
        filename    => 't/data/multiple.pl',
        expected    => array {
            item object {
                call description   => '"return" statement in "do" block';
                call line_number   => 8;
                call column_number => 9;
            };
            item object {
                call description   => '"return" statement in "do" block';
                call line_number   => 9;
                call column_number => 9;
            };
            end;
        },
    },
    {
        description => 'multiple violation for multiple subroutines',
        filename    => 't/data/multiple-subroutines.pl',
        expected    => array {
            item object {
                call description   => '"return" statement in "do" block';
                call line_number   => 8;
                call column_number => 9;
            };
            item object {
                call description   => '"return" statement in "do" block';
                call line_number   => 19;
                call column_number => 9;
            };
            end;
        },
    },
    {
        description => 'anonymous subroutine call is OK',
        filename    => 't/data/anonymous-subroutine-call.pl',
        expected    => [],
    },
    {
        description => 'separated subroutine call is OK',
        filename    => 't/data/separated-subroutines.pl',
        expected    => [],
    },
    {
        description => 'does not affect for eval block',
        filename    => 't/data/eval.pl',
        expected    => [],
    },
    {
        description => '`return` in loop block is OK',
        filename    => 't/data/loop-block.pl',
        expected    => [],
    },
    {
        description => '`return` in do-while loop block is OK',
        filename    => 't/data/do-while.pl',
        expected    => [],
    },
    {
        description => '`return` in do-until loop block is OK',
        filename    => 't/data/do-until.pl',
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
        '-single-policy' => 'ControlStructures::ProhibitReturnInDoBlock',
    );
    my @violations = $critic->critique( \$code );

    is \@violations, $testcase->{expected}, $testcase->{description};
}

done_testing;
