package Net::GeoPlanet;

use strict;
use LWP;
use URI;

our $VERSION = '0.2';
our $QUERY_API_URL = 'http://where.yahooapis.com/v1/';
our @required_params = qw(api_key);

sub places {
	my $self = shift;
    my %p = @_;
	my $url = $QUERY_API_URL;
	$url .= "places";
	if(defined $p{type}) {
		$url .= '$and(.q(' . $p{place} . '),.type(' . $p{type} . '));?';
	} else {
		$url .= '.q(\'' . $p{place} . '\')?';
	}
	$url .= 'start=' 	  . $p{start}		. '&' if defined $p{start};
	$url .= 'count='	  . $p{count}		. '&' if defined $p{count};
	$url .= 'lang='       . $p{lang}		. '&' if defined $p{lang};
	$url .= 'format='     . $p{format}		. '&' if defined $p{format};
	$url .= 'callback='   . $p{callback}	. '&' if defined $p{callback};
	$url .= 'select='     . $p{select}		. '&' if defined $p{select};
	$url .= 'appid='	  . $self->{api_key};
	return $self->_make_request($url, 'get');
}

sub place {
	my $self = shift;
	my %p = @_;
	my $url = $QUERY_API_URL;
	$url .= 'place/'    . $p{woeid} . '?';
	$url .= 'select='   . $p{select} . '&' if defined $p{select};
	$url .= 'lang='     . $p{lang} . '&' if defined $p{lang};
	$url .= 'format='   . $p{format} . '&' if defined $p{format};
	$url .= 'callback=' . $p{callback} . '&' if defined $p{callback};
	$url .= 'appid='    . $self->{api_key};
	return $self->_make_request($url, 'get');
}

sub parent {
	my $self = shift;
	my %p = @_;
	my $url = $QUERY_API_URL;
	$url .= 'place/'    . $p{woeid} . '/parent?';
	$url .= 'start=' 	. $p{start} . '&' if defined $p{start};
	$url .= 'count='	. $p{count} . '&' if defined $p{count};
	$url .= 'select='   . $p{select} . '&' if defined $p{select};
	$url .= 'lang='     . $p{lang} . '&' if defined $p{lang};
	$url .= 'format='   . $p{format} . '&' if defined $p{format};
	$url .= 'callback=' . $p{callback} . '&' if defined $p{callback};
	$url .= 'appid='    . $self->{api_key};
	return $self->_make_request($url, 'get');
}

sub ancestors {
	my $self = shift;
	my %p = @_;
	my $url = $QUERY_API_URL;
	$url .= 'place/'    . $p{woeid} . '/ancestors?';
	$url .= 'select='   . $p{select} . '&' if defined $p{select};
	$url .= 'lang='     . $p{lang} . '&' if defined $p{lang};
	$url .= 'format='   . $p{format} . '&' if defined $p{format};
	$url .= 'callback=' . $p{callback} . '&' if defined $p{callback};
	$url .= 'appid='    . $self->{api_key};
	return $self->_make_request($url, 'get');
}

sub belongtos {
	my $self = shift;
	my %p = @_;
	my $url = $QUERY_API_URL;
	$url .= 'place/'    . $p{woeid} . '/belongtos?';
	$url .= 'start=' 	. $p{start} . '&' if defined $p{start};
	$url .= 'count='	. $p{count} . '&' if defined $p{count};
	$url .= 'select='   . $p{select} . '&' if defined $p{select};
	$url .= 'lang='     . $p{lang} . '&' if defined $p{lang};
	$url .= 'format='   . $p{format} . '&' if defined $p{format};
	$url .= 'callback=' . $p{callback} . '&' if defined $p{callback};
	$url .= 'appid='    . $self->{api_key};
	return $self->_make_request($url, 'get');
}

sub neighbors {
	my $self = shift;
	my %p = @_;
	my $url = $QUERY_API_URL;
	$url .= 'place/'    . $p{woeid} . '/neighbors?';
	$url .= 'start=' 	. $p{start} . '&' if defined $p{start};
	$url .= 'count='	. $p{count} . '&' if defined $p{count};
	$url .= 'select='   . $p{select} . '&' if defined $p{select};
	$url .= 'lang='     . $p{lang} . '&' if defined $p{lang};
	$url .= 'format='   . $p{format} . '&' if defined $p{format};
	$url .= 'callback=' . $p{callback} . '&' if defined $p{callback};
	$url .= 'appid='    . $self->{api_key};
	return $self->_make_request($url, 'get');
}

sub siblings {
	my $self = shift;
	my %p = @_;
	my $url = $QUERY_API_URL;
	$url .= 'place/'    . $p{woeid} . '/siblings?';
	$url .= 'start=' 	. $p{start} . '&' if defined $p{start};
	$url .= 'count='	. $p{count} . '&' if defined $p{count};
	$url .= 'select='   . $p{select} . '&' if defined $p{select};
	$url .= 'lang='     . $p{lang} . '&' if defined $p{lang};
	$url .= 'format='   . $p{format} . '&' if defined $p{format};
	$url .= 'callback=' . $p{callback} . '&' if defined $p{callback};
	$url .= 'appid='    . $self->{api_key};
	return $self->_make_request($url, 'get');
}

sub children {
	my $self = shift;
	my %p = @_;
	my $url = $QUERY_API_URL;
	$url .= 'place/'    . $p{woeid} . '/children?';
	$url .= 'start=' 	. $p{start} . '&' if defined $p{start};
	$url .= 'count='	. $p{count} . '&' if defined $p{count};
	$url .= 'select='   . $p{select} . '&' if defined $p{select};
	$url .= 'lang='     . $p{lang} . '&' if defined $p{lang};
	$url .= 'format='   . $p{format} . '&' if defined $p{format};
	$url .= 'callback=' . $p{callback} . '&' if defined $p{callback};
	$url .= 'appid='    . $self->{api_key};
	return $self->_make_request($url, 'get');
}

sub placetypes {
	my $self = shift;
	my %p = @_;
	my $url = $QUERY_API_URL;
	if(defined $p{type}) {
		$url .= "placetypes.type(" . $p{type} . ")?";
	} else {
		$url .= "placetypes?";
	}
	$url .= 'lang='       . $p{lang} . '&' if defined $p{lang};
	$url .= 'format='   . $p{format} . '&' if defined $p{format};
	$url .= 'callback=' . $p{callback} . '&' if defined $p{callback};
	$url .= 'select='   . $p{select} . '&' if defined $p{select};
	$url .= 'start=' 	. $p{start} . '&' if defined $p{start};
	$url .= 'count='	. $p{count} . '&' if defined $p{count};
	$url .= 'appid=' . $self->{api_key};
	return $self->_make_request($url, 'get');
}

sub placetype {
	my $self = shift;
	my %p = @_;
	my $url = $QUERY_API_URL;
	$url .= "placetype/"	. $p{woeid}		. '?';
	$url .= 'lang='			. $p{lang}		. '&' if defined $p{lang};
	$url .= 'format='		. $p{format}	. '&' if defined $p{format};
	$url .= 'callback='		. $p{callback}	. '&' if defined $p{callback};
	$url .= 'select='		. $p{select}	. '&' if defined $p{select};
	$url .= 'appid='		. $self->{api_key};
	return $self->_make_request($url, 'get');
}

sub _make_request {
	my $self = shift;
	my $url = shift;
	my $method = shift;
	my $u = URI->new($url);

	my $response = $self->{browser}->$method($u, 'Accept' => "application/xml");

 	die "$method on $url failed: " . $response->status_line
		unless ( $response->is_success );

	return $response->content;
}

sub _check {
    my $self = shift;
    foreach my $param ( @required_params ) {
        if ( not defined $self->{$param} ) {
            die "Missing required parameter '$param'";
        }
    }
}

sub new {
    my $proto  = shift;
    my $class  = ref $proto || $proto;
    my %params = @_;
    my $client = bless \%params, $class;

    # Verify arguments
    $client->_check;

    $client->{browser} = LWP::UserAgent->new;

    return $client;
}

1;

__END__

=head1 NAME

Net::GeoPlanet - Access Yahoo's GeoPlanet location service

=head1 SYNOPSIS

	use Net::GeoPlanet;
	use Data::Dumper;

	my $geoplanet = Net::GeoPlanet->new(api_key => $api_key);

	print Dumper($geoplanet->places(place => "Woodside, NY 11377"));

	print Dumper($geoplanet->place(
					woeid => "2507854",
					format => "json"
				));

	print Dumper($geoplanet->parent(
					woeid => "638242",
					select => "long",
					lang => "fr-CA"
				));

=head1 ABOUT

Yahoo! GeoPlanet helps bridge the gap between the real and virtual worlds by
providing an open, permanent, and intelligent infrastructure for
geo-referencing data on the Internet.

For more information see http://developer.yahoo.com/geo/

=head1 METHODS


=head2 new

Creates the object that will be used. It takes an arguement, which is the key
assigned to you by Yahoo.

=head2 places

Returns a collection of places that match a specified place name, and
optionally, a specified place type. The resources in the collection are long
representations of each place (unless short representations are explicitly
requested).

=head2 place

Returns a resource containing the long representation of a place (unless a
short representation is explicitly requested).

=head2 parent

Returns a resource for the parent of a place. A place has only one parent.
The resource is the short representation of the parent (unless a long
representation is requested).

=head2 ancestors

Returns a collection of places in the parent hierarchy (the parent, the parent
of parent, etc.). The resources in the collection are short representations of
each place (unless a long representation is specifically requested).

=head2 belongtos

Returns a collection of places that have a place as a child or descendant
(child of a child, etc). The resources in the collection are short
representations of each place (unless a long representation is specifically
requested).

=head2 neighbors

Returns a collection of places that neighbor of a place. The resources in the
collection are short representations of each place (unless a long
representation is requested).

Note that neighbors are not necessarily geographically contiguous.

=head2 siblings

Returns a collection of places that are siblings of a place. Siblings share
the same parent and place type as the given place. The resources in the
collection are short representations of each place (unless a long
representation is requested).

=head2 children

Returns a collection of places that are children of a place. The resources
in the collection are short representations of each place (unless a long
representation is requested).

=head2 placetypes

Returns the complete collection of place types supported in GeoPlanet.
The resources in the collection each describe a single place type.

=head2 placetype

Returns a resource that describes a single place type.

=head1 MATRIX PARAMETERS

GeoPlanet supports several parameters (name/value pairs) called "matrix
parameters" that allow users to request small portions of potentially large
collections. Matrix parameters follow the collection name or filter they
refer to. The place, parent, ancestors and palcetype subroutines do not
support these parameters.

=head2 start

Skip first 'N' results

	$geoplanet->places(place => "Woodside, NY 11377", start => 1);

=head2 count

Return a maximum of N results. A count of 0 is interpreted as
'no maximum'

	$geoplanet->children(woeid => "23424977", count => 5);

=head1 QUERY PARAMETERS

GeoPlanet supports several parameters (name/value pairs) called
"query parameters" that allow users to specify a particular language or
format for the response. Query parameters follow the resource/collection
name, filter, and any matrix parameters.

=head2 lang

Return names in specified language (RFC 4646)

	$geoplanet->places(place => "Woodside, NY 11377", lang => "fr-CA");

=head2 format

Return results in specified format.
Accepted values are "xml", "json", "geojson".

	$geoplanet->neighbors(woeid => "2347563", format =>"json");

=head2 callback

Return JSON results wrapped in a JavaScript function call.
Only used when format=json or format=geojson

	$geoplanet->neighbors(
		woeid => "2347563",
		format =>"json",
		callback => "myfunction"
	);

=head2 select

Return results in specified representation.
Accepted values are "short", "long".

	$geoplanet->belongtos(woeid => "23424900", select => "short");

=head1 BUGS

None known

=head1 DEVELOPERS

The latest code for this module can be found at

	http://www.exit2shell.com/cgi-bin/cvsweb.cgi/Net-GeoPlanet/

=head1 AUTHOR

Written by Steven Kreuzer <skreuzer@exit2shell.com>

=head1 COPYRIGHT

Copyright (c) 2008, Steven Kreuzer

All rights reserved.  This program is free software; you can
redistribute it and/or modify it under the same terms as Perl
itself.

=cut
