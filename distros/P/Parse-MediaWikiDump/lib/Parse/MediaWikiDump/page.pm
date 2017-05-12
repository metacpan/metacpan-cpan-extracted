package Parse::MediaWikiDump::page;

our $VERSION = '1.0.4';

use strict;
use warnings;
use List::Util;

sub new {
	my ($class, $data, $category_anchor, $case_setting, $namespaces) = @_; 
	my $self = {};

	bless($self, $class);

	$$self{DATA} = $data;
	$$self{CACHE} = {};
	$$self{CATEGORY_ANCHOR} = $category_anchor;
	$$self{NAMESPACES} = $namespaces;

	return $self;
}

sub namespace {
	my ($self) = @_;
	my $title = $self->title;
	my $namespace = '';
	
	return $$self{CACHE}{namespace} if defined $$self{CACHE}{namespace};
	
	if ($title =~ m/^([^:]+):(.*)/) {
		foreach (@{ $self->{NAMESPACES} } ) {
			my ($num, $name) = @$_;
			if ($1 eq $name) {
				$namespace = $1;
				last;
			}
		}
	}

	$$self{CACHE}{namespace} = $namespace;

	return $namespace;
}

sub categories {
	my ($self) = @_;
	my $anchor = $$self{CATEGORY_ANCHOR};

	return $$self{CACHE}{categories} if defined($$self{CACHE}{categories});

	my $text = $$self{DATA}{text};
	my @cats;
	
	while($text =~ m/\[\[$anchor:\s*([^\]]+)\]\]/gi) {
		my $buf = $1;

		#deal with the pipe trick
		$buf =~ s/\|.*$//;
		push(@cats, $buf);
	}

	return undef if scalar(@cats) == 0;

	$$self{CACHE}{categories} = \@cats;

	return \@cats;
}

sub redirect {
	my ($self) = @_;
	my $text = $$self{DATA}{text};

	return $$self{CACHE}{redirect} if exists($$self{CACHE}{redirect});

	if ($text =~ m/^#redirect\s*:?\s*\[\[([^\]]*)\]\]/i) {
		$$self{CACHE}{redirect} = $1;
		return $1;
	} else {
		$$self{CACHE}{redirect} = undef;
		return undef;
	}
}

sub title {
	my ($self) = @_;
	return $$self{DATA}{title};
}

sub id {
	my ($self) = @_;
	return $$self{DATA}{id};
}

sub revision_id {
	my ($self) = @_;
	return $$self{DATA}{revision_id};
}

sub timestamp {
	my ($self) = @_;
	return $$self{DATA}{timestamp};
}

sub username {
	my ($self) = @_;
	return $$self{DATA}{username};
}

sub userid {
	my ($self) = @_;
	return $$self{DATA}{userid};
}

sub userip {
	my ($self) = @_;
	return $$self{DATA}{userip};
}

sub minor {
	my ($self) = @_;
	return $$self{DATA}{minor};
}

sub text {
	my ($self) = @_;
	return \$$self{DATA}{text};
}

1;

__END__
=head1 NAME

Parse::MediaWikiDump::page - Object representing a specific revision of a MediaWiki page

=head1 ABOUT

This object is returned from the "next" method of Parse::MediaWikiDump::Pages 
and Parse::MediaWikiDump::Revisions. You most likely will not be creating instances
of this particular object yourself instead you use this object to access the information
about a page in a MediaWiki instance.

=head1 SYNOPSIS
  
  $pages = Parse::MediaWikiDump::Pages->new('pages-articles.xml');
  
  #get all the records from the dump files, one record at a time
  while(defined($page = $pages->next)) {
    print "title '", $page->title, "' id ", $page->id, "\n";
  }

=head1 STATUS

This software is being RETIRED - MediaWiki::DumpFile is the official successor to
Parse::MediaWikiDump and includes a compatibility library called MediaWiki::DumpFile::Compat
that is 100% API compatible and is a near perfect standin for this module. It is faster
in all instances where it counts and is actively maintained. Any undocumented deviation
of MediaWiki::DumpFile::Compat from Parse::MediaWikiDump is considered a bug and will
be fixed. 

=head1 METHODS

=over 4

=item $page->redirect

Returns an empty string (such as '') 
for the main namespace or a string 
containing the name of the namespace.
 
=item $page->categories

Returns a reference to an array that 
contains a list of categories or undef 
if there are no categories. This method 
does not understand templates and may 
not return all the categories the article actually belongs in. 
 
=item $page->title

Returns a string of the full article title including the namespace if present
  
=item $page->namespace

Returns a string of the namespace of the article or an empty string if the article is in the default namespace
  
=item $page->id

Returns a number that is the id for the page in the MediaWiki instance
  
=item $page->revision_id

Returns a number that is the revision id for the page in the MediaWiki instance
  
=item $page->timestamp

Returns a string in the following format: 2005-07-09T18:41:10Z
  
=item $page->username

Returns a string of the username responsible for this specific revision of the article or undef if the editor was anonymous
  
=item $page->userid

Returns a number that is the id for the user returned by $page->username or undef if the editor was anonymous

=item $page->userip

Returns a string of the IP of the editor if the edit was anonymous or undef otherwise
  
=item $page->minor

Returns 1 if this article was flaged as a minor edit otherwise returns 0
  
=item $page->text
  
Returns a reference to a string that contains the article title text

=back 