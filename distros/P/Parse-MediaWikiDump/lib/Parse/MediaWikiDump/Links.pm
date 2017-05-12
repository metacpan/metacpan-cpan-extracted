package Parse::MediaWikiDump::Links;

#this needs to be fully replaced by MediaWiki::DumpFile::Compat
#because it uses a much more correct SQL parser

our $VERSION = '1.0.6';

use strict;
use warnings;

sub new {
	my ($class, $source) = @_;
	my $self = {};
	$$self{BUFFER} = [];

	bless($self, $class);

	$self->open($source);
	#fix for bug 58196 
	#$self->init;

	return $self;
}

sub next {
	my ($self) = @_;
	my $buffer = $$self{BUFFER};
	my $link;

	while(1) {
		if (defined($link = pop(@$buffer))) {
			last;
		}

		#signals end of input
		return undef unless $self->parse_more;
	}

	return Parse::MediaWikiDump::link->new($link);
}

#private functions with OO interface
sub parse_more {
	my ($self) = @_;
	my $source = $$self{SOURCE};
	my $need_data = 1;
	
	while($need_data) {
		my $line = <$source>;

		last unless defined($line);

		while($line =~ m/\((\d+),(-?\d+),'(.*?)'\)[;,]/g) {
			push(@{$$self{BUFFER}}, [$1, $2, $3]);
			$need_data = 0;
		}
	}

	#if we still need data and we are here it means we ran out of input
	if ($need_data) {
		return 0;
	}
	
	return 1;
}

sub open {
	my ($self, $source) = @_;

	if (ref($source) ne 'GLOB') {
		die "could not open $source: $!" unless
			open($$self{SOURCE}, $source);
	} else {
		$$self{SOURCE} = $source;
	}

	binmode($$self{SOURCE}, ':utf8');

	return 1;
}

sub init {
	my ($self) = @_;
	my $source = $$self{SOURCE};
	my $found = 0;
	
	while(<$source>) {
		if (m/^LOCK TABLES `pagelinks` WRITE;/) {
			$found = 1;
			last;
		}
	}

	die "not a MediaWiki link dump file" unless $found;
}

#depreciated backwards compatibility methods

#replaced by next()
sub link {
	my ($self) = @_;
	$self->next(@_);
}


1;
__END__

=head1 NAME

Parse::MediaWikiDump::Links - Object capable of processing link dump files

=head1 ABOUT

This object is used to access content of the SQL based category dump files by providing an iterative interface
for extracting the indidivual article links to the same. Objects returned are an instance of Parse::MediaWikiDump::link. 

=head1 SYNOPSIS
  
  $pmwd = Parse::MediaWikiDump->new;
  $links = $pmwd->links('pagelinks.sql');
  $links = $pmwd->links(\*FILEHANDLE);
  
  #print the links between articles 
  while(defined($link = $links->next)) {
    print 'from ', $link->from, ' to ', $link->namespace, ':', $link->to, "\n";
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

=item Parse::MediaWikiDump::Links->new

Create a new instance of a page links dump file parser

=item $links->next

Return the next available Parse::MediaWikiDump::link object or undef if there is no more data left

=back

=head1 EXAMPLE

=head2 List all links between articles in a friendly way

  #!/usr/bin/perl
  
  use strict;
  use warnings;
  
  use Parse::MediaWikiDump;
  
  my $pmwd = Parse::MediaWikiDump->new;
  my $links = $pmwd->links(shift) or die "must specify a pagelinks dump file";
  my $dump = $pmwd->pages(shift) or die "must specify an article dump file";
  my %id_to_namespace;
  my %id_to_pagename;
  
  binmode(STDOUT, ':utf8');
  
  #build a map between namespace ids to namespace names
  foreach (@{$dump->namespaces}) {
  	my $id = $_->[0];
  	my $name = $_->[1];	
  
  	$id_to_namespace{$id} = $name;
  }
  
  #build a map between article ids and article titles
  while(my $page = $dump->next) {
  	my $id = $page->id;
  	my $title = $page->title;
  
  	$id_to_pagename{$id} = $title;
  }
  
  $dump = undef; #cleanup since we don't need it anymore
  
  while(my $link = $links->next) {
  	my $namespace = $link->namespace;
  	my $from = $link->from;
  	my $to = $link->to;
  	my $namespace_name = $id_to_namespace{$namespace};	
  	my $fully_qualified;
  	my $from_name = $id_to_pagename{$from};
  
  	if ($namespace_name eq '') {
  		#default namespace
  		$fully_qualified = $to;
  	} else {
  		$fully_qualified = "$namespace_name:$to";
  	}
  
  	print "Article \"$from_name\" links to \"$fully_qualified\"\n";
  }


