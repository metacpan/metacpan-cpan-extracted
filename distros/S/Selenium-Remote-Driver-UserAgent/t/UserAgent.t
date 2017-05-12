#! /usr/bin/perl

use strict;
use warnings;

use Test::More;
use IO::Socket::INET;
use Test::ParallelSubtest max_parallel => 5;
use Selenium::Remote::Driver 0.2102;
use Selenium::Remote::Driver::UserAgent;

my @browsers = qw/chrome firefox/;
my @agents = qw/iphone ipad_seven ipad android_phone android_tablet/;
my @orientations = qw/portrait landscape/;

# my @browsers = qw/firefox/;
# my @agents = qw/iphone/;
# my @orientations = qw/landscape/;

my $sock = IO::Socket::INET->new(
    PeerAddr => 'localhost',
    PeerPort => 4444
);

UNENCODED: {
    my $dua = Selenium::Remote::Driver::UserAgent->new(
        browserName => 'firefox',
        agent => 'iphone'
    );

    my $caps = $dua->caps(unencoded => 1);
    isa_ok($caps->{desired_capabilities}->{firefox_profile},
           'Selenium::Remote::Driver::Firefox::Profile');
}

foreach my $browser (@browsers) {
    foreach my $agent (@agents) {
        foreach my $orientation (@orientations) {
            my $test_prefix = join(', ', ($browser, $agent, $orientation));
            bg_subtest $test_prefix => sub {
                my $dua = Selenium::Remote::Driver::UserAgent->new(
                    browserName => $browser,
                    agent => $agent,
                    orientation => $orientation
                );

                my $caps = $dua->caps;
                validate_caps_structure($caps, $browser, $orientation);

              SKIP: {
                    skip 'Release tests not required for installation', 4 unless $ENV{RELEASE_TESTING};
                    skip 'remote driver server not found', 4 unless defined $sock;

                    my $driver = Selenium::Remote::Driver->new_from_caps(%$caps);
                    my $actual_caps = $driver->get_capabilities;

                    ok($actual_caps->{browserName} eq $browser, 'correct browser');

                    my $details = $driver->execute_script(qq/return {
                        agent: navigator.userAgent,
                        width: window.innerWidth,
                        height: window.innerHeight
                    }/);

                    # useragents with underscores in them need to be trimmed.
                    # for example, ipad_seven only has 'iPad' in its user
                    # agent, not 'ipad_seven'
                    my $expected_agent = $agent;
                    $expected_agent =~ s/_.*//;
                    cmp_ok($details->{agent} , '=~', qr/$expected_agent/i, 'user agent includes ' . $agent);
                    cmp_ok($details->{width} , '==', $dua->_get_size->{width}, 'width is correct.');
                    cmp_ok($details->{height}, '==', $dua->_get_size->{height} , 'height is correct.');
                }
            };

        }
    }
}

sub validate_caps_structure {
    my ($caps, $browser, $orientation)  = @_;

    ok(exists $caps->{desired_capabilities}, 'caps: has desired capabilities key');

    my $desired = $caps->{desired_capabilities};
    ok($desired->{browserName} eq $browser, 'caps: with proper browser');

    if ($browser eq 'chrome') {
        my $chrome_args = join('', @{ $desired->{chromeOptions}->{args} });
        ok($chrome_args =~ /user-agent/, 'caps: Chrome has user agent arg');
        ok($chrome_args =~ /window-size/, 'caps: Chrome has window size arg');
    }
    elsif ($browser eq 'firefox') {
        ok(exists $desired->{firefox_profile}, 'caps: FF has firefox_profile key');
    }

    my $size = $caps->{inner_window_size};
    my $cmp = $orientation eq 'portrait' ? '>' : '<';
    cmp_ok($size->[0], $cmp, $size->[1], 'window size: correct order');
}



done_testing;
