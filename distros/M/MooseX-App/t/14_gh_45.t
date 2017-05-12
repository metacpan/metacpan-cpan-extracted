# -*- perl -*-

# t/14_gh_45.t - Boolean negation

use Test::Most tests => 3+1;
use Test::NoWarnings;

use lib 't/testlib';

{
    package Test14;
    use MooseX::App::Simple;

    option 'b1' => (
        is             => 'rw',
        isa            => 'Bool',
        cmd_negate     => ['not-b1']
    );

    option 'not_b1' => (
        is             => 'rw',
        isa            => 'Bool',
    );

    option 'b2yes' => (
        is             => 'rw',
        isa            => 'Bool',
        cmd_negate     => ['no_b2','unb2']
    );

    sub run {
        my ($self) = @_;
        return "ok";
    }
}

subtest 'boolean negation' => sub {
    plan tests => 4;
    Test14->meta->app_fuzzy(0);

    {
        MooseX::App::ParsedArgv->new(argv => [qw(--not-b1 --not_b1 --b2yes)]);
        my $test01 = Test14->new_with_options();
        isa_ok($test01,'Test14');
        is($test01->b1,0,'Did not set b1');
        is($test01->not_b1,1,'Did set not_b1');
        is($test01->b2yes,1,'Did set b2');
    }
};

subtest 'boolean fuzzy negation' => sub {
    plan tests => 4;
    Test14->meta->app_fuzzy(1);

    {
        MooseX::App::ParsedArgv->new(argv => [qw(--not-b --not_b --b2)]);
        my $test01 = Test14->new_with_options();
        isa_ok($test01,'Test14');
        is($test01->b1,0,'Did not set b1');
        is($test01->not_b1,1,'Did set not_b1');
        is($test01->b2yes,1,'Did set b2');
    }
};

subtest 'ambiguous negation' => sub {
    plan tests => 3;
    Test14->meta->app_fuzzy(1);

    {
        MooseX::App::ParsedArgv->new(argv => [qw(--not-b1 --b1 --b2yes --no_b2 --unb2 --b2 --un)]);
        my $test01 = Test14->new_with_options();
        isa_ok($test01,'Test14');
        is($test01->b1,1,'Did  set b1');
        is($test01->b2yes,0,'Did not set b2');
    }
};