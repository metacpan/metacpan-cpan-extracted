#!/usr/bin/perl
use strict;
use warnings;
use Test::More qw/no_plan/;
use Test::Exception;
use Socialtext::WikiFixture::TestUtils qw/fixture_ok/;

BEGIN {
    use lib 'lib';
    use_ok 'Socialtext::WikiObject::TestPlan';
}

sel_fixture_ok (
    name => 'Simple Selenese',
    plan => <<EOT,
* Fixture: Selenese
| *Command* | *Option 1* | *Option 2* |
| open | / |
| verifyTitle | monkey |
| verifyTextPresent | water |
| verifyText | //body | pen? |
| verifyText | //body | qr/pen?/ |
| confirmation_like | pen? |
| confirmation_like | qr/pen?/ |
| clickAndWait | foo | |
| selectAndWait | foo | bar |
EOT
    tests => [
        [ open_ok => '/' ],
        [ title_like => qr/\Qmonkey\E/ ],
        [ text_like => ['//body', qr/\Qwater\E/] ],
        [ text_like => ['//body', qr/\Qpen?\E/] ],
        [ text_like => ['//body', qr/pen?/s] ],
        [ confirmation_like => qr/\Qpen?\E/ ],
        [ confirmation_like => qr/pen?/s ],
        [ click_ok => 'foo' ],
        [ wait_for_page_to_load_ok => 10000 ],
        [ select_ok => ['foo', 'bar'] ],
        [ wait_for_page_to_load_ok => 10000 ],
    ],
);

sel_fixture_ok (
    name => 'Specific timeout',
    plan => <<EOT,
* Fixture: Selenese
| clickAndWait | foo | |
EOT
    tests => [
        [ click_ok => 'foo' ],
        [ wait_for_page_to_load_ok => 9 ],
    ],
    fixture_args => { 
        selenium_timeout => 9,
    },
);

Pass_in_selenium: {
    my $selenium = 'fake';
    my $f = Socialtext::WikiFixture::Selenese->new(selenium => $selenium);
    is $f->{selenium}, $selenium, "didn't create a new selenium";
    $f->end_hook;
    is $f->{selenium}, $selenium, "didn't undef selenium";
}

Variable_interpolation: {
    my $f = Socialtext::WikiFixture::Selenese->new(selenium => 'fake');
    eval { $f->_munge_options('%%foo%%') };
    like $@, qr/Undef var - 'foo'/;
    $f->{foo} = 'bar';
    my @opts = $f->_munge_options('%%foo%%');
    is_deeply \@opts, ['bar'];
}

Missing_mandatory_args: {
    throws_ok { Socialtext::WikiFixture::Selenese->new }
              qr/Selenium host/;
    throws_ok { Socialtext::WikiFixture::Selenese->new(host => 'foo') }
              qr/Selenium browser_url/;
}

Optional_selenium_port: {
    my $f = Socialtext::WikiFixture::Selenese->new(
        host => 'foo', 
        browser_url => 'bar',
        port => 1234,
    );
    is $f->{selenium}{args}{host}, 'foo';
    is $f->{selenium}{args}{browser_url}, 'bar';
    is $f->{selenium}{args}{port}, 1234;
}

Selenese_command_mapping: {
    sel_fixture_ok (
        name => 'text_like with 1 arg',
        plan => <<EOT,
| verifyText | foo | |
EOT
        tests => [
            [ text_like => ['//body', qr/foo/] ],
        ],
    );
}

Camel_cased_commands: {
    my %commands = (
        SuperDuper => 'super_duper',
        Super => 'super',
    );
    my $f = Socialtext::WikiFixture::Selenese->new(selenium => 'fake');
    for my $long (keys %commands) {
        is $f->_munge_command($long), $commands{$long}, $long;
    }
}

Quote_as_regex: {
    my $f = Socialtext::WikiFixture::Selenese->new(selenium => 'fake');
    is $f->quote_as_regex(), qr//;
    is $f->quote_as_regex('foo'), qr/\Qfoo\E/;
    is $f->quote_as_regex('qr/foo/'), qr/foo/s;
}

sub sel_fixture_ok {
    my %args = @_;

    fixture_ok( 
        default_fixture => 'Selenese',
        %args,
    );
}

Higher_permissions: {
    my %browsers = (
        '*firefox' => '*chrome',
        '*iexplore' => '*iehta',
    );
    while (my ($low,$high) = each %browsers) {
        for my $on (1, 0) {
            my $rester = Socialtext::Resting::Mock->new;
            my $text = join("",
                "* Fixture: Selenese\n",
                $on ? "* HighPermissions\n" : "",
                "| open | / |\n",
            );

            $rester->put_page('Test Plan', $text);

            my $plan = Socialtext::WikiObject::TestPlan->new(
                rester => $rester,
                page => 'Test Plan',
                fixture_args => {
                    browser => $low,
                    host => 'selenium-server',
                    username => 'testuser',
                    password => 'password',
                    browser_url => 'http://server',
                    workspace => 'foo',
                },
            );

            my $wanted = $on ? $high : $low,
            my $not = $on ? '' : 'not ';

            $plan->run_tests;
            is  $plan->{fixture}{browser}, 
                $wanted, 
                "${not}HighPermissions causes = $wanted",
        }
    }
}
