#!/usr/bin/perl
use strict;
use warnings;

use URI::file;

use Test::More;
plan tests => 60;

use_ok( 'Mozilla::Mechanize' );

sub as_WML($) {
    my $link = shift;
    return [ (undef) x 4 ] unless $link;
    return [ $link->url||undef, $link->text||undef,
             $link->name||undef, (lc $link->tag)||undef ];
}

my $uri = URI::file->new_abs("t/html/find_link.html")->as_string;

isa_ok my $t = Mozilla::Mechanize->new(visible => 0), 'Mozilla::Mechanize';

ok $t->get($uri), "get($uri)";

SKIP: {
    skip "->success doesn't work yet", 1;
    ok($t->success, "Fetched $uri") or die "Can't get test page";
}

my @all_links1 = $t->links;
my $all_links2 = $t->links;
is scalar(@all_links1), 16,  "Returned all links (16)";
is scalar(@$all_links2), 16, "Returned all links from scalar context";
is_deeply \@all_links1, $all_links2, "structures are the same";

my $x;
$x = $t->find_link();
isa_ok( $x, 'Mozilla::Mechanize::Link' );
is( as_WML($x)->[0], "http://blargle.com/", "First link on the page" );
is( $x->url, "http://blargle.com/", "First link on the page" );

$x = $t->find_link( text => "CPAN A" );
isa_ok( $x, 'Mozilla::Mechanize::Link' );
is( as_WML($x)->[0], "http://a.cpan.org/", "First CPAN link" );
is( $x->url, "http://a.cpan.org/", "First CPAN link" );

$x = $t->find_link( url => "CPAN" );
ok( !defined $x, "No url matching CPAN" );

$x = $t->find_link( text_regex => qr/CPAN/, n=>3 );
isa_ok( $x, 'Mozilla::Mechanize::Link' );
is( as_WML($x)->[0], "http://c.cpan.org/", "3rd CPAN text" );
is( $x->url, "http://c.cpan.org/", "3rd CPAN text" );

$x = $t->find_link( text => "CPAN", n=>34 );
ok( !defined $x, "No 34th CPAN text" );

$x = $t->find_link( text_regex => qr/(?i:cpan)/ );
isa_ok( $x, 'Mozilla::Mechanize::Link' );
is( as_WML($x)->[0], "http://a.cpan.org/", "Got 1st cpan via regex" );
is( $x->url, "http://a.cpan.org/", "Got 1st cpan via regex" );

$x = $t->find_link( text_regex => qr/cpan/i );
isa_ok( $x, 'Mozilla::Mechanize::Link' );
is( as_WML($x)->[0], "http://a.cpan.org/", "Got 1st cpan via regex" );
is( $x->url, "http://a.cpan.org/", "Got 1st cpan via regex" );

$x = $t->find_link( text_regex => qr/cpan/i, n=>153 );
ok( !defined $x, "No 153rd cpan link" );

$x = $t->find_link( url => "http://b.cpan.org/" );
isa_ok( $x, 'Mozilla::Mechanize::Link' );
is( as_WML($x)->[0], "http://b.cpan.org/", "Got b.cpan.org" );
is( $x->url, "http://b.cpan.org/", "Got b.cpan.org" );

$x = $t->find_link( url => "http://b.cpan.org", n=>2 );
ok( !defined $x, "Not a second b.cpan.org" );

$x = $t->find_link( url_regex => qr/[b-d]\.cpan\.org/, n=>2 );
isa_ok( $x, 'Mozilla::Mechanize::Link' );
is( as_WML($x)->[0], "http://c.cpan.org/", "Got c.cpan.org" );
is( $x->url, "http://c.cpan.org/", "Got c.cpan.org" );

{
    my @wanted_links= (
        # url, text, name, tag
        [ "http://a.cpan.org/", "CPAN A", undef, "a" ],
        [ "http://b.cpan.org/", "CPAN B", undef, "a" ],
        [ "http://c.cpan.org/", "CPAN C", "bongo", "a" ],
        [ "http://d.cpan.org/", "CPAN D", undef, "a" ],
    );
    my @links1 = map as_WML( $_ ) => $t->find_all_links( text_regex => qr/CPAN/ );
    my @links2 = map as_WML( $_ ) => @{
        scalar $t->find_all_links( text_regex => qr/CPAN/ )
    };
    is_deeply( \@links1, \@wanted_links, "Correct links came back" )
        || diag "@links1";
    is_deeply \@links2, \@wanted_links, "Same links in scalar context";

    my $linkref = [ map as_WML( $_ ) => $t->find_all_links(
         text_regex => qr/CPAN/
    ) ];
    is_deeply( $linkref, \@wanted_links, "Correct links came back" );
}

# Check combinations of links
$x = $t->find_link( text => "News" );
isa_ok( $x, 'Mozilla::Mechanize::Link' );
is( as_WML($x)->[0], "http://www.msnbc.com/", "First News is MSNBC" );
is( $x->url, "http://www.msnbc.com/", "First News is MSNBC" );

$x = $t->find_link( text => "News", url_regex => qr/bbc/ );
isa_ok( $x, 'Mozilla::Mechanize::Link' );
is( as_WML($x)->[0], "http://www.bbc.co.uk/", "First BBC news link" );
is( $x->url, "http://www.bbc.co.uk/", "First BBC news link" );
is( as_WML($x)->[1], "News", "First BBC news text" );
is( $x->text, "News", "First BBC news text" );

$x = $t->find_link( text => "News", url_regex => qr/cnn/ );
isa_ok( $x, 'Mozilla::Mechanize::Link' );
is( as_WML($x)->[0], "http://www.cnn.com/", "First CNN news link" );
is( $x->url, "http://www.cnn.com/", "First CNN news link" );
is( as_WML($x)->[1], "News", "First CNN news text" );
is( $x->text, "News", "First CNN news text" );

AREA_CHECKS: {
    my @wanted_links = (
        # url, text, name, tag
	[ "http://www.cnn.com/", "CNN", undef, "a" ],
	[ "http://www.cnn.com/", "News", "Fred", "a" ],
#	[ "http://www.cnn.com/area", undef, undef, "area" ],
	[ "http://www.cnn.com/area", undef, 'Marty', "area" ],
    );
    my @links = map as_WML( $_ ) => $t->find_all_links(
        url_regex => qr/cnn\.com/
    );
    is_deeply( \@links, \@wanted_links, "Correct links came back" );

    my $linkref = [ map as_WML( $_ ) =>  $t->find_all_links(
        url_regex => qr/cnn\.com/
    ) ];
    is_deeply( $linkref, \@wanted_links, "Correct links came back" );
}

$x = $t->find_link( name => "bongo" );
isa_ok( $x, 'Mozilla::Mechanize::Link' );
is_deeply( as_WML($x), [ "http://c.cpan.org/", "CPAN C", "bongo", "a" ],
           'Got the CPAN C link' );

$x = $t->find_link( name_regex => qr/^[A-Z]/, n => 2 );
isa_ok( $x, 'Mozilla::Mechanize::Link' );
is_deeply( as_WML($x), [ "http://www.cnn.com/", "News", "Fred", "a" ],
           'Got 2nd link that begins with a capital' );

my @as = $t->find_link( tag => 'a', n => 'all' );
$x = $t->find_link( tag => 'a', n => 3 );
isa_ok( $x, 'Mozilla::Mechanize::Link' );
is_deeply as_WML($x), [ "http://b.cpan.org/", "CPAN B", undef, "a" ],
          'Got 3rd <A> tag';

$x = $t->find_link(tag_regex => qr/^(a|iframe)$/i, n => 6);
isa_ok($x, 'Mozilla::Mechanize::Link');
is_deeply as_WML($x), [ "http://d.cpan.org/", "CPAN D", undef, "a" ],
          'Got 6th <A> or <IFRAME> tag';

TODO: {
    $x = $t->find_link( text => "Rebuild Index" );
    isa_ok( $x, 'Mozilla::Mechanize::Link' );
    todo_skip "New feature in 'Mech', needs to be ported", 1;
    is_deeply( as_WML($x),
               [ "/cgi-bin/MT/mt.cgi", "Rebuild Index", undef, "a" ],
               'Got the JavaScript link' );
}

$t->close();
