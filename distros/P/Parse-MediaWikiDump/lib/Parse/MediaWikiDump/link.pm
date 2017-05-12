package Parse::MediaWikiDump::link;

our $VERSION = '1.0.3';

#you must pass in a fully populated link array reference
sub new {
	my ($class, $self) = @_;

	bless($self, $class);

	return $self;
}

sub from {
	my ($self) = @_;
	return $$self[0];
}

sub namespace {
	my ($self) = @_;
	return $$self[1];
}

sub to {
	my ($self) = @_;
	return $$self[2];
}

1;

=head1 NAME

Parse::MediaWikiDump::link - Object representing a link from one article to another

=head1 ABOUT

This object is used to access the data associated with each individual link between articles in a MediaWiki instance. 

=head1 STATUS

This software is being RETIRED - MediaWiki::DumpFile is the official successor to
Parse::MediaWikiDump and includes a compatibility library called MediaWiki::DumpFile::Compat
that is 100% API compatible and is a near perfect standin for this module. It is faster
in all instances where it counts and is actively maintained. Any undocumented deviation
of MediaWiki::DumpFile::Compat from Parse::MediaWikiDump is considered a bug and will
be fixed. 

=head1 METHODS

=over 4

=item $link->from

Returns the article id (not the name) that the link orginiates from.

=item $link->namespace

Returns the namespace id (not the name) that the link points to

=item $link->to

Returns the article title (not the id and not including the namespace) that the link points to

