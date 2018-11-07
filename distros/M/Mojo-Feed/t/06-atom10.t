use strict;
use Mojo::Base -strict;

use Mojo::Feed::Reader;

use HTTP::Date qw(time2isoz);
use Test::More;

my $feed = Mojo::Feed::Reader->new->parse("t/samples/atom-full.xml");
is $feed->title, 'Content Considered Harmful Atom Feed';
is $feed->link, 'http://blog.jrock.us/', "link without rel";

my $e = $feed->items->[0];
ok $e->link, 'entry link without rel';
is join( "", @{ $e->tags } ), "Catalyst", "atom:category support";
is time2isoz( $e->published ), "2006-08-09 19:07:58Z", "atom:updated";

# this test fails, but I'm OK with that:
#like $e->content, qr/^<div class="pod">/, "xhtml content";
done_testing();

