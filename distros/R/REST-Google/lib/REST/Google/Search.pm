#
# $Id: Search.pm 9 2008-04-29 21:17:12Z esobchenko $

package REST::Google::Search;

use strict;
use warnings;

use version; our $VERSION = qv('1.0.8');

use constant {
	WEB => 'http://ajax.googleapis.com/ajax/services/search/web',
	VIDEO => 'http://ajax.googleapis.com/ajax/services/search/video',
	NEWS => 'http://ajax.googleapis.com/ajax/services/search/news',
	LOCAL => 'http://ajax.googleapis.com/ajax/services/search/local',
	IMAGES => 'http://ajax.googleapis.com/ajax/services/search/images',
	BOOKS => 'http://ajax.googleapis.com/ajax/services/search/books',
	BLOGS => 'http://ajax.googleapis.com/ajax/services/search/blogs',
	PATENT => 'http://ajax.googleapis.com/ajax/services/search/patent',
};

require Exporter;
require REST::Google;
use base qw/Exporter REST::Google/;

our @EXPORT_OK = qw/WEB VIDEO NEWS LOCAL IMAGES BOOKS BLOGS PATENT/;

__PACKAGE__->service( WEB );

sub responseData {
	my $self = shift;
	return undef unless defined $self->{responseData};
	return bless $self->{responseData}, 'REST::Google::Search::Data';
}

package # hide from CPAN
	REST::Google::Search::Data;

sub results {
	my $self = shift;
	if ( wantarray ) {
		return map { bless $_, $_->{GsearchResultClass} } @{ $self->{results} };
	}
	[ map { bless $_, $_->{GsearchResultClass} } @{ $self->{results} } ];
}

sub cursor {
	my $self = shift;
	return bless $self->{cursor}, 'REST::Google::Search::Cursor';
}

package # hide from CPAN
	REST::Google::Search::Cursor;

use base qw/Class::Accessor/;

{
	my @fields = qw(
		moreResultsUrl
		currentPageIndex
	);

	__PACKAGE__->mk_ro_accessors( @fields );
}

sub estimatedResultCount {
	my $self = shift;
	my $count = $self->{estimatedResultCount};
	defined $count ? $count : 0;
}

sub pages {
	my $self = shift;
	my $pages = $self->{pages} || [];
	if (wantarray) {
		return map { bless $_, 'REST::Google::Search::Pages' } @{ $pages };
	}
	[ map { bless $_, 'REST::Google::Search::Pages' } @{ $pages } ];
}

package # hide from CPAN
	REST::Google::Search::Pages;

use base qw/Class::Accessor/;

{
	my @fields = qw(
		start
		label
	);

	__PACKAGE__->mk_ro_accessors( @fields );
}

#
# Search Result Classes
#

package # hide from CPAN 
	GwebSearch;

use base qw/Class::Accessor/;

{
	my @fields = qw(
		unescapedUrl
		url
		visibleUrl
		title
		titleNoFormatting
		content
		cacheUrl
	);

	__PACKAGE__->mk_ro_accessors( @fields );
}

package # hide from CPAN
	GvideoSearch;

use base qw/Class::Accessor/;

{
	my @fields = qw(
		title
		titleNoFormatting
		content
		url
		published
		publisher
		duration
		tbWidth
		tbHeight
		tbUrl
		playUrl
		author
		viewCount
		rating
	);

	__PACKAGE__->mk_ro_accessors( @fields );
}

package # hide from CPAN
	GnewsSearch;

use base qw/Class::Accessor/;

{
	my @fields = qw(
		title
		titleNoFormatting
		unescapedUrl
		url
		clusterUrl
		content
		publisher
		location
		publishedDate
		relatedStories
		image
		language
	);

	__PACKAGE__->mk_ro_accessors( @fields );
}

package # hide from CPAN
	GlocalSearch;

use base qw/Class::Accessor/;

{
	my @fields = qw(
		title
		titleNoFormatting
		url
		lat
		lng
		streetAddress
		city
		region
		country
		phoneNumbers
		addressLines
		ddUrl
		ddUrlToHere
		ddUrlFromHere
		staticMapUrl
		listingType
		content
	);

	__PACKAGE__->mk_ro_accessors( @fields );
}

package # hide from CPAN
	GimageSearch;

use base qw/Class::Accessor/;

{
	my @fields = qw(
		title
		titleNoFormatting
		unescapedUrl
		url
		visibleUrl
		originalContextUrl
		width
		height
		tbWidth
		tbHeight
		tbUrl
		content
		contentNoFormatting
	);

	__PACKAGE__->mk_ro_accessors( @fields );
}

package # hide from CPAN
	GbookSearch;

use base qw/Class::Accessor/;

{
	my @fields = qw(
		title
		titleNoFormatting
		unescapedUrl
		url
		authors
		bookId
		publishedYear
		pageCount
		thumbnailHtml
	);

	__PACKAGE__->mk_ro_accessors( @fields );
}

package # hide from CPAN
	GblogSearch;

use base qw/Class::Accessor/;

{
	my @fields = qw(
		title
		titleNoFormatting
		postUrl
		content
		author
		blogUrl
		publishedDate
	);

	__PACKAGE__->mk_ro_accessors( @fields );
}

package # hide from CPAN
	GpatentSearch;

use base qw/Class::Accessor/;

{
	my @fields = qw(
		title
		titleNoFormatting
		content
		unescapedUrl
		url
		applicationDate
		patentNumber
		patentStatus
		assignee
		tbUrl
	);

	__PACKAGE__->mk_ro_accessors( @fields );
}

1;
