#!/usr/bin/perl
use strict;
use warnings;
use Test::More qw/no_plan/;
use lib 't/lib';
use Socialtext::Resting::Mock;

BEGIN {
    use lib 'lib';
    use_ok 'Socialtext::WikiObject::TestPlan';
    use_ok 'Socialtext::WikiFixture::Null', 'get_num_calls';
}

Basic_plan: {
    testplan_ok( 
        num => 2,
        plan_content => <<EOT,
* Fixture: Null
| Foo |
| bar |
| |
EOT
    );
}

Recursive_plan: {
    testplan_ok( 
        num => 2,
        plan_content => <<EOT,
* [Plan1]
* Wah-wah
* [Plan2]
EOT
        pages => { 
            'Plan1' => "* Fixture: Null\n| foo |\n",
            'Plan2' => "* Fixture: Null\n| foo |\n",
        },
    );
}

Recursive_plan_with_default_fixture: {
    testplan_ok( 
        num => 2,
        plan_content => <<EOT,
* [Plan1]
* Wah-wah
* [Plan2]
EOT
        pages => { 
            'Plan1' => "* Fixture: Null\n| bar |\n",
            'Plan2' => "* Fixture: Null\n| foo |\n",
        },
        tp_args => { default_fixture => 'Null' },
    );
}

Default_fixture: {
    testplan_ok( 
        num => 2,
        plan_content => <<EOT,
| Foo |
| bar |
EOT
        tp_args => { default_fixture => 'Null' },
    );
}

No_fixture: {
    testplan_ok( 
        num => 0,
        plan_content => <<EOT,
| Foo |
| bar |
EOT
    );
}

Invalid_fixture: {
    testplan_ok( 
        should_die => 1,
        plan_content => <<EOT,
* Fixture: Monkey
| Foo |
| bar |
EOT
    );
}

sub testplan_ok {
    my %args = @_;

    my $rester = Socialtext::Resting::Mock->new;
    $rester->put_page('Test Plan' => $args{plan_content});
    for my $p (keys %{ $args{pages} }) {
        $rester->put_page($p, $args{pages}{$p});
    }
    my %tp_args = (
        rester => $rester,
        page => 'Test Plan',
        %{ $args{tp_args} || {} },
    );
    my $plan = Socialtext::WikiObject::TestPlan->new(
        %tp_args,
        fixture_args => {
            server => 'http://server',
            workspace => 'foo',
        },
    );
    
    if ($args{should_die}) {
        eval { $plan->run_tests };
        ok $@, "Dies";
    }
    else {
        $plan->run_tests;
        is get_num_calls(), $args{num};
    }
}

