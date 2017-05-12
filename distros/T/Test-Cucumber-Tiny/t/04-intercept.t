use strict;
use warnings;
use Try::Tiny;
use Test::Cucumber::Tiny;
use Test::More tests => 3;

$ENV{CUCUMBER_VERBOSE} = "diag";

subtest "next step" => sub {
    my @cases = (
        {
            Scenario => "normal calculation",
            Before   => "Setup buffer for pressed keys",
            Given => [ "press 3", "press +", "press 2", "press *", "press 3", ],
            When  => "find answer",
            Then  => "is 9",
        },
        {
            Scenario => "same formula but don't x 3",
            Before   => "Setup buffer for pressed keys",
            Given    => [
                "press 3", "press +", "press 2", "skip x 3",
                "press *", "press 3",
            ],
            When  => "find answer",
            Then  => "is 5",
            After => [
                "Rollover answer for next scenario",
            ]
        },
        {
            Scenario => "use the last scenario answer",
            Before   => [
                "Setup buffer for pressed keys",
            ],
            Given    => [
                "use last answer", "press +", "press 6", "press *", "press 2",
            ],
            When => "find answer",
            Then => "is 17",
        }
    );

    my $cucumber = Test::Cucumber::Tiny->new( scenarios => \@cases );

    foreach my $ba (qw( Before After )) {
        try {
            $cucumber->$ba;
        }
        catch {
            like $_, qr/Missing regexp or coderef/,
              "Cover $ba Missing regexp or coderef";
        }
    }

    $cucumber->Before(
        qr/foobar/ => sub {
            die "Never reach";
        }
    );

    $cucumber->After(
        sub {
            is 1 + 1, 2, "for dev Cover";
        }
    );

    $cucumber->Before(
        sub {
            my $c = shift;
            diag shift;
            $c->{FEATURE_WIDE}{answer} ||= 0;
            $c->{formula} = q{};
        }
    );

    $cucumber->Given(
        qr/use last answer/ => sub {
            my $c = shift;
            diag shift;
            $c->{formula} .= $c->{FEATURE_WIDE}{answer};
        }
    );

    $cucumber->Given(
        qr/^press (.+)/ => sub {
            my $c = shift;
            diag shift;
            my $key = $1;
            $c->{formula} .= $1;
        }
    );

    $cucumber->Any(
        qr/skip/ => sub {
            my $c = shift;
            diag shift;
            $cucumber->NextStep;
        }
    );

    $cucumber->When(
        qr/find answer/ => sub {
            my $c       = shift;
            my $subject = shift;
            diag "$subject of $c->{formula}";
            $c->{answer} = eval $c->{formula};
        }
    );

    $cucumber->Then(
        qr/is (\d+)/ => sub {
            my $c = shift;
            is $c->{answer}, $1, shift;
        }
    );

    $cucumber->After(
        qr/rollover/i => sub {
            my $c = shift;
            $c->{FEATURE_WIDE}{answer} = $c->{answer};
        }
    );

    $cucumber->Test;
};

subtest "skip example" => sub {
    my @cases = (
        {
            Scenario => "normal calculation",
            Given    => [ "next example <skip>", "add <num>", ],
            Examples => [
                { num => 1, skip => 0, answer => 1 },
                { num => 2, skip => 1, answer => 1 },
                { num => 3, skip => 0, answer => 4 },
                { num => 4, skip => 1, answer => 4 },
                { num => 5, skip => 0, answer => 9 },
            ],
            When => "find answer",
            Then => "is <answer>",
        },
    );

    my $cucumber = Test::Cucumber::Tiny->new( scenarios => \@cases );

    $cucumber->Before(
        sub {
            my $c = shift;
            $c->{formula} ||= q{0};
            $c->{answer}  ||= 0;
        }
    );

    $cucumber->Given(
        qr/^add (\d+)/ => sub {
            my $c = shift;
            diag shift;
            $c->{formula} .= "+$1";
        }
    );

    $cucumber->Given(
        qr/next example (\d)/ => sub {
            my $c = shift;
            diag shift;
            my $skip = $1;
            $cucumber->NextExample if $skip;
        }
    );

    $cucumber->When(
        qr/find answer/ => sub {
            my $c       = shift;
            my $subject = shift;
            my $formula = $c->{formula};
            $c->{answer} = eval $formula;
            diag "$subject - $formula";
        }
    );

    $cucumber->Then(
        qr/is (\d+)/ => sub {
            my $c        = shift;
            my $expected = $1;
            is $c->{answer}, $expected, shift;
        }
    );

    $cucumber->Test;
};

subtest "Interception Total Test" => sub {

    my $cucumber = Test::Cucumber::Tiny->Scenarios(
        {
            Scenario => "next example at BEFORE",
            Before   => "next example",
            Given    => "remember <something> in FEATURE_WIDE memory",
            When     => "remember <something> in FEATURE_WIDE memory",
            Then     => "<something> in the FEATURE_WIDE memory",
            Examples => [
                {
                    something => 1
                },
                {
                    something => 2
                },
            ]
        },
        {
            Scenario => "next scenario at Given",
            Given    => "next scenario",
            When     => "remember foobar in FEATURE_WIDE memory",
            Then     => "foobar in the FEATURE_WIDE memory",
        },
        {
            Scenario => "next scenario at When",
            Given    => "use FEATURE_WIDE memory",
            When     => [
                "next scenario",
                "remember foobar in FEATURE_WIDE memory",
            ],
            Then     => "foobar in the FEATURE_WIDE memory",
        },
        {
            Scenario => "next scenario at Then",
            Given    => "use FEATURE_WIDE memory",
            When     => "remember foobar in FEATURE_WIDE memory",
            Then     => [
                "next scenario",
                "foobar in the FEATURE_WIDE memory",
            ],
        },
        {
            Scenario => "passed from previous scenario",
            Given    => "use FEATURE_WIDE memory",
            When     => "next step",
            Then     => [
                "nothing in the FEATURE_WIDE memory",
                "next step",
            ]
        }
    );

    $cucumber->Any(
        qr/next scenario/ => sub {
            shift;
            diag shift;
            $cucumber->NextScenario;
        }
    );

    $cucumber->Any(
        qr/next example/ => sub {
            shift;
            diag shift;
            $cucumber->NextExample;
        }
    );

    $cucumber->Any(
        qr/next step/ => sub {
            shift;
            diag shift;
            $cucumber->NextStep;
        }
    );

    $cucumber->When(
        qr/^remember (\S+) in FEATURE_WIDE memory/ => sub {
            my $c         = shift;
            my $something = $1;
            diag shift;
            $c->{FEATURE_WIDE}{memory} = $something;
        }
    );

    $cucumber->When(
        qr/next step/ => sub {
            shift;
            diag shift;
            $cucumber->NextStep;
        }
    );

    $cucumber->Then(
        qr/^(\S+) in the FEATURE_WIDE memory/ => sub {
            my $c        = shift;
            my $subject  = shift;
            my $expected = $1;
            if ( $expected eq "nothing" ) {
                $expected = undef;
            }
            is $expected, $c->{FEATURE_WIDE}{memory}, $subject;
        }
    );

    $cucumber->Test;
};
