package Socialtext::WikiFixture::TestUtils;
use strict;
use warnings;
use Test::More;
use Socialtext::Resting::Mock;
use mocked 'Test::WWW::Selenium', qw/$SEL/;

use base 'Exporter';
our @EXPORT_OK = qw/fixture_ok/;

my $rester = Socialtext::Resting::Mock->new;

sub fixture_ok {
    my %args = @_;

    ok 1, $args{name};

    $rester->put_page('Test Plan', $args{plan});
    my $plan = Socialtext::WikiObject::TestPlan->new(
        rester => $rester,
        page => 'Test Plan',
        default_fixture => $args{default_fixture},
        fixture_args => {
            host => 'selenium-server',
            username => 'testuser',
            password => 'password',
            browser_url => 'http://server',
            workspace => 'foo',
            %{ $args{fixture_args} || {} },
        },
    );

    if ($args{sel_setup}) {
        for my $s (@{$args{sel_setup}}) {
            $SEL->set_return_value(@$s);
        }
    }

    $plan->run_tests;

    for my $t (@{$args{tests}}) {
        $SEL->method_args_ok(@$t);
    }

    $SEL->method_args_ok('stop', undef);
    $SEL->empty_ok($args{extra_calls_ok});
}

1;
