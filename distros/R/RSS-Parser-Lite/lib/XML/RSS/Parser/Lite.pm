package XML::RSS::Parser::Lite::Item;

use strict;

our $VERSION = '0.12';

sub new {
	my $class = shift;

	my $self = {
		'title', '',
		'url', '',
		'description', '',
		'pubDate', '',
		'author', '',
		'category', '',
		'comments', '',
		'enclosure', '',
		'guid', '',
		'source', '',
		@_,
	};
	
	bless($self, $class);
	return $self;
}


sub set {
	my $self = shift;

	my %defs = (@_);
	foreach my $k (keys %defs) {
		$self->{$k} = $defs{$k};
	}
}

sub get {
	my $self = shift;
	
	my $want = shift;
	return $self->{$want};
}


package XML::RSS::Parser::Lite;

use strict;
use XML::Parser::Lite;

our $VERSION = '0.12';

sub new { 
	my $class = shift;

	my $parser = new XML::Parser::Lite;
	my $self = {
		# mandatory
		parser		=> $parser,
		place		=> '',
		title		=> '',
		url		=> '',
		description	=> '',
		items		=> [],
		latest		=> new XML::RSS::Parser::Lite::Item,
		# optionals
		pubDate		=> '',
		language	=> '',
		copyright	=> '',
		managingEditor	=> '',
		webMaster	=> '',
		pubDate	=> '',
		lastBuildDate	=> '',
		category	=> '',
		generator	=> '',
		docs	=> '',
		cloud	=> '',
		ttl	=> '',
		image	=> '',
		rating	=> '',
		textInput	=> '',
		skipHours	=> '',
		skipDays	=> '',
	};

	$self->{parser}->setHandlers(
		Final	=> sub { shift; $self->final(@_) },
		Start	=> sub { shift; $self->start(@_) },
		End	=> sub { shift; $self->end(@_) },
		Char	=> sub { shift; $self->char(@_) },
	);

	bless($self, $class);
	return $self;
}

sub parse {
	my $self = shift;
	my $xml = shift;
	
	$self->{parser}->parse($xml);
}


sub final { 
	my $self = shift; 

	$self->{parser}->setHandlers(Final => undef, Start => undef, End => undef, Char => undef);
}

sub start {
	my $self = shift;
	my $tag = shift;
	
	$self->{place} .= "/$tag";
	$self->{latest} = $self->add if ($self->{place} eq '/rss/channel/item');
	$self->{latest} = $self->add if ($self->{place} eq '/rdf:RDF/item');
}

sub char {
	my $self = shift;
	my $text = shift;

	# set item
	$self->{latest}->set('title', $text) if ($self->{place} eq '/rss/channel/item/title');
	$self->{latest}->set('url', $text) if ($self->{place} eq '/rss/channel/item/link');
	$self->{latest}->set('description', $text) if ($self->{place} eq '/rss/channel/item/description');
	# optional fields
	$self->{latest}->set('pubDate', $text) if ($self->{place} eq '/rss/channel/item/pubDate');
	$self->{latest}->set('author', $text) if ($self->{place} eq '/rss/channel/item/author');
	$self->{latest}->set('category', $text) if ($self->{place} eq '/rss/channel/item/category');
	$self->{latest}->set('comments', $text) if ($self->{place} eq '/rss/channel/item/comments');
	$self->{latest}->set('enclosure', $text) if ($self->{place} eq '/rss/channel/item/enclosure');
	$self->{latest}->set('guid', $text) if ($self->{place} eq '/rss/channel/item/guid');
	$self->{latest}->set('source', $text) if ($self->{place} eq '/rss/channel/item/source');

# compatibility with RSS1.0
	$self->{latest}->set('title', $text) if ($self->{place} eq '/rdf:RDF/item/title');
	$self->{latest}->set('url', $text) if ($self->{place} eq '/rdf:RDF/item/link');
	$self->{latest}->set('description', $text) if ($self->{place} eq '/rdf:RDF/item/description');
	
	# set channel
	$self->{title} = $text if ($self->{place} eq '/rss/channel/title');
	$self->{url} = $text if ($self->{place} eq '/rss/channel/link');
	$self->{description} = $text if ($self->{place} eq '/rss/channel/description');
	$self->{pubDate} = $text if ($self->{place} eq '/rss/channel/pubDate');
}

sub end { 
	my $self = shift; 
	my $tag = shift;
	
	my $place = $self->{place};
	$place = substr($place, 0, length($place)-length($tag)-1); # regex here causes segmentation fault!

# compatibility with RSS1.0
	$self->{place} = $place;
	$self->{title} = $tag if ($self->{place} eq '/rdf:RDF/channel/title');
	$self->{url} = $tag if ($self->{place} eq '/rdf:RDF/channel/link');
	$self->{description} = $tag if ($self->{place} eq '/rdf:RDF/channel/description');
}



sub add {
	my ($self) = shift;
	
	my $it = new XML::RSS::Parser::Lite::Item(@_);
	push(@{$self->{items}}, $it);

	return $it;
}


sub count {
	my $self = shift;
	return scalar @{$self->{items}};
}


sub get {
	my $self = shift;
	
	my $what = shift;
	if ($what =~ /^\d*$/) {
		return @{$self->{items}}[$what];
	}
	
	return $self->{$what};
}


1;

__END__


=head1 NAME

XML::RSS::Parser::Lite - A simple pure perl RSS parser.


=head1 SYNOPSIS

	use XML::RSS::Parser::Lite;
	use LWP::Simple;
	
	my $xml = get("http://url.to.rss");
	my $rp = new XML::RSS::Parser::Lite;
	$rp->parse($xml);
	
	print $rp->get('title') . " " . $rp->get('url') . " " . $rp->get('description') . "\n";

	for (my $i = 0; $i < $rp->count(); $i++) {
		my $it = $rp->get($i);
		print $it->get('title') . " " . $it->get('url') . " " . $it->get('description') . "\n";
		# some RSSv2.0 optional parameters may have been set:
		if (defined $it->get('pubDate') { print "publication date found: " . $it->get('pubDate')."\n"; }
	}


=head1 DESCRIPTION

XML::RSS::Parser::Lite is a simple pure perl RSS parser. It uses XML::Parser::Lite as backend.

For the fields available via C<get>, please refer to the documentation: L<http://www.rss-specifications.com/rss-specifications.htm>, for RSS v2.0: L<http://cyber.law.harvard.edu/rss/rss.html>.

=head1 METHODS

=over 4

=item $rp = new XML::RSS::Parser::Lite;

Creates a new RSS parser.


=item $rp->parse($xml);

Parses the supplied xml.


=item $items = $rp->count();

Returns the number of items in the RSS file.


=item $value = $rp->get($what);

Integers sent to get returns and XML::RSS::Parser::Lite::Item while the strings title, url, and description returns these
values from the RSS channel information.

=item $value = $item->get($what);

On an XML::RSS::Parser::Lite::Item this can return the strings title, url, or description.
All RSS v2.0 values are accessible, provided they are present in the feed: L<http://cyber.law.harvard.edu/rss/rss.html>

=back

=head1 LICENSE

Copyright (c) 2003-2013 Erik Bosrup. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Erik Bosrup, erik@bosrup.com ; Thomas Blanchard, thomasfp.blanchard@gmail.com

