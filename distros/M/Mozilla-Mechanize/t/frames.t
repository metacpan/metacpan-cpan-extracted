#!/usr/bin/perl
use strict;
use warnings;

use URI::file;

use Test::More;
plan tests => 9;

use_ok 'Mozilla::Mechanize';

my $url = URI::file->new_abs( "t/html/frames.html" )->as_string;

isa_ok my $moz = Mozilla::Mechanize->new(visible => 0), "Mozilla::Mechanize";
isa_ok $moz->{agent}, "Mozilla::Mechanize::Browser";

ok $moz->get( $url ), "get($url)";

is $moz->title, "Frames Page", "->title method";

# This should be in find_links.t, technically
my $x = $moz->find_link(tag_regex => qr/^frame$/i, n => 2);
isa_ok($x, 'Mozilla::Mechanize::Link');
is lc($x->tag), 'frame', 'tag=frame';
is $x->name, 'right', 'name=right';
like $x->url, qr/basic\.html$/, 'url like "basic.html"';

$moz->close();
