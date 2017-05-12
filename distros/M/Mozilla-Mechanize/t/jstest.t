#!/usr/bin/perl
use strict;
use warnings;

use URI::file;

use Test::More;
plan tests => 4;

use_ok 'Mozilla::Mechanize';

my $uri = URI::file->new_abs( "t/html/jstest.html" )->as_string;
my $new_uri = URI::file->new_abs( "t/html/jstestok.html" )->as_string;

isa_ok my $moz = Mozilla::Mechanize->new(visible => 0), 'Mozilla::Mechanize';

$moz->get( $uri );

sleep 1;    # XXX: problem with _wait_while_busy

is $moz->title, 'JS Redirection Success', "Right title()";

# for some reason, submits cause Mozilla to append a question mark,
# so this just tests if the beginning part of the URL is right
like $moz->uri, qr/^$new_uri/, "Got the new uri()";

$moz->close();
