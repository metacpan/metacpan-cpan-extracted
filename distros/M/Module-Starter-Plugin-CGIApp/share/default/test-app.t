#!/usr/bin/perl

# Test application functionality
use strict;
use warnings;
use Test::More tests => 1;
use Test::WWW::Mechanize::CGIApp;
use <tmpl_var main_module>;

my $mech = Test::WWW::Mechanize::CGIApp->new;

$mech->app(
    sub {
        my $app = <tmpl_var main_module>->new(PARAMS => {

        });
        $app->run();
    }
);

$mech->get_ok(q{/});

