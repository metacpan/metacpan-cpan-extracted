#! /usr/bin/perl

use strict;
use warnings;
use Test::More;
use Selenium::UserAgent;

eval {
    my $bad = Selenium::UserAgent->new(
        browserName => 'invalid',
        agent => 'iphone'
    );
};

ok( $@ =~ /coercion.*failed/, 'browser name is coerced');

eval {
    my $bad = Selenium::UserAgent->new(
        browserName => 'chrome',
        agent => 'invalid'
    );
};

ok( $@ =~ /coercion.*failed/, 'agent is coerced');

eval {
    my $bad = Selenium::UserAgent->new(
        browserName => 'chrome',
        agent => 'iphone',
        orientation => 'invalid'
    );
};

ok( $@ =~ /coercion.*failed/, 'orientation is coerced');

done_testing;
