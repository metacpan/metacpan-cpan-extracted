#!/usr/bin/perl
use strict;
use warnings;

use URI::file;

use Test::More;
plan tests => 20;

use_ok 'Mozilla::Mechanize';

my $uri = URI::file->new_abs('t/html/basic.html')->as_string;
my $urit = URI::file->new_abs('t/html/basic.txt')->as_string;
my @image_uri = map(URI::file->new_abs("t/img/$_")->as_string,
                    qw(reddot.gif greendot.jpg bluedot.png));

isa_ok my $moz = Mozilla::Mechanize->new(visible => 0),
  "Mozilla::Mechanize";

ok $moz->get($uri), "get($uri)";
isa_ok my $doc = $moz->get_document, 'Mozilla::DOM::Document';

is $moz->title, "Test Page", "->title method";
is $moz->ct, "text/html", "->ct method (text/html)";

ok $moz->follow_link(text => 'Basic text'), "Follow textlink";
is $moz->ct, 'text/plain', "->ct method (text/plain)";

ok $moz->reload(), "reload()";
is $moz->ct, 'text/plain', "same content-type (text/plain)";

$moz->quiet(1);
ok ! $moz->follow_link(n => 'all'), 'not follow_link(n => "all")';

(my $ouri = $uri) =~ s|:///?([A-Z]):|:///\U$1:|i;
ok $moz->back, "back()";
is $moz->ct, 'text/html', "different content-type (text/html)";
is $moz->uri, $ouri, "back to $ouri";

for my $img (@image_uri) {
    ok $moz->get($img), "get($img)";
    my $ctype = $img =~ /\.(\w+)$/ ? $1 : 'unknown';
    $ctype =~ s/jpg/jpeg/;
    is $moz->ct, "image/$ctype", "ct() eq 'image/$ctype'";
}
