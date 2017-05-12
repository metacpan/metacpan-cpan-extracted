#!/usr/bin/perl
use strict;
use warnings;

use URI::file;

use Test::More;
plan tests => 20;

use_ok 'Mozilla::Mechanize';

my $uri = URI::file->new_abs( "t/html/image-parse.html" )->as_string;
my $url1 = URI::file->new_abs( "t/html/wango.jpg" )->as_string;
my $url2 = URI::file->new_abs( "t/html/bongo.gif" )->as_string;

isa_ok my $moz = Mozilla::Mechanize->new(visible => 0), "Mozilla::Mechanize";
isa_ok $moz->agent, "Mozilla::Mechanize::Browser";

ok $moz->get( $uri ), "get($uri)";
is $moz->title, "Image Test Page", "->title method";
is $moz->ct, "text/html", "->ct method";

my @images = $moz->images;
is scalar @images, 2, "Only two images";

for(@images){for my$a(qw(tag url alt)){print"$a: ",$_->$a,$/}}


my $first = $images[0];
is lc($first->tag), "img", "img tag";
(my $juri = $url1 ) =~ s|:///?([a-z]):|:///\U$1:|i;
is $first->url, $juri, "src=\"$juri\"";
is $first->alt, "The world of the wango", "alt=The world of the wango";

is $first->height, 142, "height";
is $first->width, 43, "width";

my $second = $images[1];
is lc $second->tag, "input", "input tag";
# XXX: for some reason, <img src> is absolute whereas <input src> is relative!
#(my $guri = $url2 ) =~ s|:///?([a-z]):|:///\U$1:|i;
#is $second->url, $guri, "src=$guri";
# XXX2: now with Firefox it's absolute for this too, so just matching the filename..
like $second->url, qr{bongo\.gif$}, 'src="bongo.gif"';
is $second->alt, '', "alt";

my $fia1 = $moz->find_image( alt => "The world of the wango" );
isa_ok $fia1, 'Mozilla::Mechanize::Image';
is $fia1, $images[0], "find_image( alt )";
my $fiar1 = $moz->find_image( alt_regex => qr/The world of/ );
isa_ok $fiar1, 'Mozilla::Mechanize::Image';
is $fiar1, $images[0], "find_image( alt_regex )";

my $imagelist = $moz->find_all_images;
is scalar(@$imagelist), 2, "find_all_images()";
