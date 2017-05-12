package Net::GNUDBSearch;

=pod

=head1 NAME

Net::GNUDBSearch - Search interface to GNUDB database

=head1 SYNOPSIS

	use Net::GNUDBSearch;
	my $search = Net::GNUDBSearch->new();
	my $results = $search->byArtist("The Prodigy");

=head1 DESCRIPTION

Net::GNUDBSearch is an interface to the website www.gnudb.org online free CD information database. Based on Net::CDDBSearch by Vitaliy Babiy. This module
allows you to search by artist and retrive a list of albums found then get their tracks.

=head1 METHODS

=cut

use warnings;
use strict;
use Carp;
use WWW::Mechanize;
use URI::Encode;
use Data::Dumper;
use XML::Simple;
use Net::GNUDBSearch::Cd;
our $VERSION = "1.01";
#########################################################

=head2 new()

	my $gnudb = Net::GNUDBSearch->new();

Constructor, returns a new instance of the search object ready for use.

=cut

#########################################################
sub new{
	my $class = shift;
	my $self = {
		'__baseUrl' => "http://www.gnudb.org",
		'__action' => undef
	};
	bless $self, $class;
	return $self;
}
##########################################################

=head2 byArtist($query)

	my $albums = $gnudb->byArtist("The Prodigy");

Returns an array reference of L<Net::GNUDBSearch::Cd> objects containing CD's found from the artist name given.

=cut

##########################################################
sub byArtist{
	my($self, $query) = @_;
	my @results = ();
	my $class = ref($self);
	if($query){
		$self->__setAction("artist");
		my $url = $self->__getSearchUrl();
        my $encoded = $class->__encode($query);
        $url .=  "/"  . $encoded;	#add search terms
		my $mech = WWW::Mechanize->new();
		print "Getting url: $url\n";
		my $res = $mech->get($url);
		if($mech->success()){
			my $content = $mech->content();
			if($content =~ m/<h2>Search Results, \d+ albums found:<\/h2>.+<br><br>(.+<hr size="1">)/s){
				my $results = $1;
				my $xml = $class->__htmlToXml($results);
				my $xs = XML::Simple->new();
    			my $ref = $xs->XMLin($xml);
				foreach my $match (@{$ref->{'match'}}){
					#print Dumper $match;
					my $a = $match->{'a'}[0];
					#get the album and artist
					my $name = $a->{'b'};
					my($cdArtist, $cdAlbum) = split(" / ", $name);
					$cdArtist =~ s/^\s+//g; #remove leading whitespace
					$cdArtist =~ s/\s+$//g; #remove trailing whitespace
					$cdAlbum =~ s/^\s+//g;  #remove leading whitespace
					$cdAlbum =~ s/\s+$//g;  #remove trailing whitespace
					#get data for the track lookup
					$a = $match->{'a'}[1];
					if($a->{'content'} =~ m/^Discid: (\w+) \/ ([a-f0-9]+)$/){
						my $cdGenre = $1;
						my $cdId = $2;
						my $objClass = $class . "::Cd";	#avoid hard coding classes
						my $config = {
							"id" => $cdId,
							"artist" => $cdArtist,
							"album" => $cdAlbum,
							"genre" => $cdGenre
						}; 
						my $cdObj = $objClass->new($config);
						push(@results, $cdObj);	#save it in the results
					}
					else{
						confess("Invalid GNUDB info");
					}
				}
			}
		}
		else{
			confess("Problem with search, code: " . $mech->status());
		}
	}
	else{
		confess("No artist given");
	}
	return \@results;	
}
#########################################################
sub __getSearchUrl{
	my$self = shift;
	my $url = undef;
	if($self->__getAction()){
		$url = $self->__getBaseUrl() . "/" . $self->__getAction();
	}
	else{
		confess("No action set");
	}
	return $url;
}
#########################################################
sub __getBaseUrl{
	my $self = shift;
	return $self->{'__baseUrl'};
}
#########################################################
sub __setAction{
	my($self, $action) = @_;
	$self->{'__action'} = $action;
	return 1;
}
#########################################################
sub __getAction{
	my $self = shift;
	return $self->{'__action'};
}
#########################################################
sub __htmlToXml{
	my($class, $html) = @_;
	my $xml = $html;
	$xml =~ s/<br>/<br\/>/g;
	$xml =~ s/(<a href="http:\/\/www.gnudb.org\/cd)/<match>$1/g;
	$xml =~ s/<hr size="1">/<\/match>/g;
	$xml =~ s/ target=_blank//g;
	$xml =~ s/&/&amp;/g;
	$xml = "<matches>" . $xml . "</matches>\n";
	return $xml;
}
#########################################################
sub __encode{
	my($class, $query) = @_;
	my $uri = URI::Encode->new();
    my $encoded = $uri->encode($query);
    $encoded =~ s/%20/\+/g;	#the gnudb search does a redirect if + signs are not used
	return $encoded;
}
#########################################################

=pod

=head1 Notes

Only retrieves the first page of results as that should be good enough to find data.

=head1 Author

MacGyveR <dumb@cpan.org>

Development questions, bug reports, and patches are welcome to the above address.

=head1 Thanks

Vitaliy Babiy <admin@mpscope.net> for module Net::CDDBSearch

=head1 Copyright

Copyright (c) 2012 MacGyveR. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 See Also

Net::CDDBSearch

=cut

#########################################################
return 1;
