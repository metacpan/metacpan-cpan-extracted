#!/usr/bin/perl
use strict;
use warnings;

use URI::file;

use Test::More;
plan tests => 8;

use_ok( 'Mozilla::Mechanize' );

my $uri = URI::file->new_abs( "t/html/tick.html" )->as_string;

isa_ok my $moz = Mozilla::Mechanize->new(visible => 0), "Mozilla::Mechanize";

$moz->get( $uri );

SKIP: {
    skip "->success doesn't work yet", 1;
    ok $moz->success, "->success";
}

ok my $prev_uri = $moz->uri, "Got an uri back";

my $form = $moz->form_number(1);
isa_ok( $form, 'Mozilla::Mechanize::Form' );

$moz->tick("foo","hello");
$moz->tick("foo","bye");
$moz->untick("foo","hello");

$moz->click( 'submit' ); $moz->_wait_while_busy;

like $moz->uri, qr/[&?]foo=bye\b/, "(un)tick actions [foo=bye]";
like $moz->uri, qr/[&?]submit=Submit\b/, "(un)tick actions [submit=Submit]";
unlike $moz->uri, qr/[&?]foo=hello\b/, "(un)tick actions ![foo=hello]";

$moz->close();
