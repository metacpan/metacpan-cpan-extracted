#!/usr/bin/perl
use strict;
use warnings;

use URI::file;

use Test::More;
plan tests => 12;

use_ok 'Mozilla::Mechanize';

my $burl = URI::file->new_abs("t/html/basic.html")->as_string;
my $furl = URI::file->new_abs("t/html/formbasics.html")->as_string;

isa_ok my $moz = Mozilla::Mechanize->new(visible => 0),
  "Mozilla::Mechanize";
isa_ok $moz->agent, "Mozilla::Mechanize::Browser";

ok $moz->get($burl), "get($burl)";

is $moz->title, "Test Page", "->title method";
is $moz->ct, "text/html", "->ct method";
like $moz->content, qr|<p>Simple paragraph</p>|i, "Content";

ok $moz->follow_link(text => 'formbasics'), "follow_link()";

(my $follow_uri = $furl ) =~ s|:///?([a-z]):|:///\U$1:|i;
is $moz->uri, $follow_uri, "new uri $follow_uri";
ok $moz->back, "back()";

(my $back_uri = $burl) =~ s|:///?([a-z]):|:///\U$1:|i;
is $moz->uri, $back_uri, "back at $back_uri";

my $link = $moz->find_link(text => 'formbasics');
is $link->name, '', "<A> has no name";

$moz->close();
