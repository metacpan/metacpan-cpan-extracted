use strict;
use warnings;
use Try::Tiny;
use Test::More tests => 3;
use Test::Cucumber::Tiny;

$ENV{CUCUMBER_VERBOSE} = "diag";

subtest "missing subject" => sub {
    my @scenarios = (
        {
            Scenario => undef,
        }
    );
    my $cucumber = Test::Cucumber::Tiny->new( scenarios => \@scenarios );
    try {
        $cucumber->Test;
    }
    catch {
        like $_, qr/Missing the name of Scenario/, "Missing subject";
    };
};

subtest "missing step" => sub {
    my @steps = qw( given when then );
    foreach my $step (@steps) {
        my @scenarios = (
            {
                Scenario       => "Test missing step '$step'",
                Given          => {},
                When           => [],
                Then           => [],
                ucfirst($step) => undef
            }
        );
        my $cucumber = Test::Cucumber::Tiny->new( scenarios => \@scenarios );
        try {
            $cucumber->Test;
        }
        catch {
            like $_, qr/Missing '$step' in scenario/i, $step;
        };
    }
};

subtest "missing precondition" => sub {
    my @scenarios = (
        {
            Scenario => "Test missing precondition",
            Givne    => {},
            When     => [],
            Then     => [],
        }
    );
    my $cucumber = Test::Cucumber::Tiny->new( scenarios => \@scenarios );
    my @commands = qw( Given When Then );
    foreach my $command(@commands) {
        try {
            $cucumber->$command(undef);
        }
        catch {
            like $_, qr/Missing '$command' condition/;
        };
        try {
            $cucumber->$command(qr/something/, undef);
        }
        catch {
            like $_, qr/Missing '$command' definition coderef/;
        };
    }
};
