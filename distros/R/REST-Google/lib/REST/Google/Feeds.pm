#
# $Id: Feeds.pm 13 2008-04-30 09:30:13Z esobchenko $

package REST::Google::Feeds;

use strict;
use warnings;

use version; our $VERSION = qv('1.0.8');

require Exporter;
require REST::Google;
use base qw/Exporter REST::Google/;

__PACKAGE__->service('http://ajax.googleapis.com/ajax/services/feed/load');

sub responseData {
	my $self = shift;
	return bless $self->{responseData}, 'REST::Google::Feeds::Data';
}

package # hide from CPAN
	REST::Google::Feeds::Data;

sub feed {
	my $self = shift;
	return bless $self->{feed}, 'REST::Google::Feeds::Feed';
}

package # hide from CPAN
	REST::Google::Feeds::Feed;

require Class::Accessor;
use base qw/Class::Accessor/;

{
	my @fields = qw(
		title
		link
		author
		description
		type
	);

	__PACKAGE__->mk_ro_accessors(@fields);
}

sub entries {
	my $self = shift;
	if (wantarray) {
		return map { bless $_, 'REST::Google::Feeds::Entry' } @{ $self->{entries} };
	}
	[ map { bless $_, 'REST::Google::Feeds::Entry' } @{ $self->{entries} } ];
}

package # hide from CPAN
	REST::Google::Feeds::Entry;

require Class::Accessor;
use base qw/Class::Accessor/;

{
	my @fields = qw(
		title
		link
		author
		publishedDate
		contentSnippet
		content
		categories
	);

	__PACKAGE__->mk_ro_accessors(@fields);
}

1;
