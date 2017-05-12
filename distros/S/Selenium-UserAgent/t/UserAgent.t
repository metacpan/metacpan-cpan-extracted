#! /usr/bin/perl

use strict;
use warnings;

use JSON;
use Test::More;
use IO::Socket::INET;
use Selenium::Remote::Driver 0.2102;
use Selenium::UserAgent;

my @browsers = qw/chrome firefox/;

my @agents = qw/iphone ipad_seven ipad android_phone android_tablet
                iphone4 iphone5 iphone6 iphone6plus ipad_mini ipad
                galaxy_s3 galaxy_s4 galaxy_s5 galaxy_note3
                nexus4 nexus10
               /;

my @orientations = qw/portrait landscape/;

# my @browsers = qw/firefox/;
# my @agents = qw/iphone/;
# my @orientations = qw/landscape/;

my $has_local_webdriver_server = IO::Socket::INET->new(
    PeerAddr => 'localhost',
    PeerPort => 4444,
    Timeout => 5
);

UNENCODED: {
    my $sua = Selenium::UserAgent->new(
        browserName => 'firefox',
        agent => 'iphone'
    );

    my $caps = $sua->caps(unencoded => 1);
    isa_ok($caps->{desired_capabilities}->{firefox_profile},
           'Selenium::Firefox::Profile');
}

foreach my $browser (@browsers) {
    foreach my $agent (@agents) {
        foreach my $orientation (@orientations) {
            my $test_prefix = join(', ', ($browser, $agent, $orientation));

            my $sua = Selenium::UserAgent->new(
                browserName => $browser,
                agent => $agent,
                orientation => $orientation
            );

            my $caps = $sua->caps;
            validate_caps_structure($caps, $browser, $orientation);

          SKIP: {
                skip 'Release tests not required for installation', 4 unless $ENV{RELEASE_TESTING};
                skip 'remote driver server not found', 4
                  unless $has_local_webdriver_server;

                my $driver = Selenium::Remote::Driver->new_from_caps(%$caps);
                my $actual_caps = $driver->get_capabilities;

                ok($actual_caps->{browserName} eq $browser, 'correct browser');

                my $details = $driver->execute_script(qq/return {
                    agent: navigator.userAgent,
                    width: window.innerWidth,
                    height: window.innerHeight
                }/);

                my $expected_agent = get_expected_agent( $agent );
                my $expected_width = $sua->_get_size->{width};
                if ($expected_width < 335 && $browser eq 'firefox') {
                    # Firefox doesn't get any smaller than 335,
                    # but some device resolutions ask for 320. We
                    # have to compensate a little in the tests.
                    $expected_width = 335;
                }
                cmp_ok($details->{agent} , '=~', $expected_agent, 'user agent includes ' . $agent);
                cmp_ok($details->{width} , '==', $expected_width, 'width is correct.');
                cmp_ok($details->{height}, '==', $sua->_get_size->{height} , 'height is correct.');
            }
        };
    }
}


sub validate_caps_structure {
    my ($caps, $browser, $orientation)  = @_;

    ok(exists $caps->{desired_capabilities}, 'caps: has desired capabilities key');

    my $desired = $caps->{desired_capabilities};
    ok($desired->{browserName} eq $browser, 'caps: with proper browser');

    if ($browser eq 'chrome') {
        my $chrome_args = to_json($desired->{chromeOptions});
        ok($chrome_args =~ /user-agent/, 'caps: Chrome has user agent arg');
        ok($chrome_args =~ /mobileEmulation.*deviceMetrics.*pixelRatio/,
           'caps: Chrome has mobile emulation arg');
    }
    elsif ($browser eq 'firefox') {
        ok(exists $desired->{firefox_profile}, 'caps: FF has firefox_profile key');
    }

    my $size = $caps->{inner_window_size};
    my $cmp = $orientation eq 'portrait' ? '>' : '<';
    cmp_ok($size->[0], $cmp, $size->[1], 'window size: correct order');
}

sub get_expected_agent {
    my ($agent) = @_;

    # all of the iphone devices start with i: iPad, iPhone. None of
    # the Android devices do: galaxy, nexus, android.
    if ($agent =~ /^i/) {
        return qr/iphone|ipad/i;
    }
    else {
        return qr/android/i;
    }
}

done_testing;
