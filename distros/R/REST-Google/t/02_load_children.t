#
# $Id$

use strict;

use Test::More tests => 21;

use_ok( "REST::Google::Translate" );
use_ok( "REST::Google::Feeds" );

use_ok( "REST::Google::Search" );
use_ok( "REST::Google::Search::Web" );
use_ok( "REST::Google::Search::Local" );
use_ok( "REST::Google::Search::Video" );
use_ok( "REST::Google::Search::Blogs" );
use_ok( "REST::Google::Search::News" );
use_ok( "REST::Google::Search::Books" );
use_ok( "REST::Google::Search::Images" );
use_ok( "REST::Google::Search::Patent" );


# Translate
can_ok( "REST::Google::Translate", qw(responseData) );
can_ok( "REST::Google::Translate::Data", qw(translatedText) );

# Feeds
can_ok( "REST::Google::Feeds", qw(responseData) );
can_ok( "REST::Google::Feeds::Data", qw(feed) );
can_ok( "REST::Google::Feeds::Feed", qw(entries title link author description type) );
can_ok( "REST::Google::Feeds::Entry", qw(title link author publishedDate contentSnippet content categories) );

# Search
can_ok( "REST::Google::Search", qw(responseData) );
can_ok( "REST::Google::Search::Data", qw(results cursor) );
can_ok( "REST::Google::Search::Cursor", qw(moreResultsUrl currentPageIndex estimatedResultCount pages) );
can_ok( "REST::Google::Search::Pages", qw(start label) );
