package Net::API::Nominatim::Model::BoundingBox;

use strict;
use warnings;

our $VERSION = '0.03';

use Data::Roundtrip qw/json2perl no-unicode-escape-permanently/;

# export nothing otherwise we need to adjust our sub names
# to avoid clashes, e.g. fromHash, use these like
#   Net::API::Nominatim::Model::BoundingBox::fromHash()

#use Exporter;
#our (@EXPORT_OK, %EXPORT_TAGS);
#BEGIN {
#	@EXPORT_OK = qw/ fromHash fromArrayOfArrays fromArray fromJSONArray fromRandom /;
#	%EXPORT_TAGS = ( all => [@EXPORT_OK] );
#}

### Constructor, all fields are initialised to 0.0
### (whereas in Address.pm they are initialised to '', even lat/lon)
sub new {
	my ($class, $params) = @_;

	my $self = {
		lat1 => 0.0,
		lat2 => 0.0,
		lon1 => 0.0,
		lon2 => 0.0,
	};
	bless $self => $class;
	return $self unless defined $params;

	if( ref($params)eq'HASH' ){
		fromHash($params, $self);
	} elsif( ref($params)eq'' ){
		if( ! defined fromJSONArray($params, $self) ){ print STDERR __PACKAGE__."->new(), line ".__LINE__." : error, input JSON string was malformed, failed.\n"; return undef }
	} elsif( ref($params) eq __PACKAGE__ ){
		fromArray($params->toArray(), $self);
	} elsif( ref($params)eq'ARRAY' && scalar(@$params) && ref($params->[0])eq'ARRAY'){
		fromArrayOfArrays($params, $self);
	} elsif( ref($params)eq'ARRAY' && scalar(@$params) && ref($params->[0])eq''){
		fromArray($params, $self);
	}
	return $self;
}

###########################################
# getters and setters at the same time
#
sub fields { return sort keys %{$_[0]} }
sub lat1 { return $_[1] ? $_[0]->{lat1} = $_[1] : $_[0]->{lat1} }
sub lon1 { return $_[1] ? $_[0]->{lon1} = $_[1] : $_[0]->{lon1} }
sub lat2 { return $_[1] ? $_[0]->{lat2} = $_[1] : $_[0]->{lat2} }
sub lon2 { return $_[1] ? $_[0]->{lon2} = $_[1] : $_[0]->{lon2} }

# randomise all fields of CURRENT object to random
# numbers specific for lat/lon, 
# (see randomLat(), randomLon() on how this is done).
# By default empty and undef fields will not be randomised.
# Unless optional 2nd parameter is set to 1. Default is 0.
# It will/can also randomise the boundingbox object.
sub randomise { 
	for ('lat1', 'lat2'){
		$_[0]->{$_} = randomLat();
	}
	for ('lon1', 'lon2'){
		$_[0]->{$_} = randomLon();
	}
}

# Clone current object and return the new one.
# It can return undef on failure.
sub clone { return Net::API::Nominatim::Model::BoundingBox->new($_[0]->toArray()) }

# It checks equality between our current object and the
# second object passed as the input parameter.
# It returns 1 if equal, 0 if not,
# it first checks if the types of objects are the same.
sub equals {
	my ($x, $y) = @_;
	return 0 unless ref($x) eq ref($y); # not same object type
	return 1 if "$x" eq "$y"; # same pointer

	for(keys %$x){
		return 0 unless $x->{$_} == $y->{$_};
	}
	return 1 # equal
}

# return a 1D array adhering to the Nominatim notation: [lat1,lat2,lon1,lon2]
# It returns an Array.
sub toArray {
	my $self = $_[0];
	return [ $self->lat1(), $self->lat2(), $self->lon1(), $self->lon2() ];
}

# Stringify to the "normal" notation of
# a 2D array like: "[[lat1,lon1],[lat2,lon2]]"
# Unlike what Nominatim returns which
# is a 1D array like: "[lat1,lat2,lon1,lon2]".
# It returns a String.
sub toString {
	my $self = $_[0];
	return '[[' . $self->lat1() . ', ' . $self->lon1() . '],[' . $self->lat2() . ', ' . $self->lon2() . ']]'
}
# Stringify to the Nominatim notation, like: "[lat1,lat2,lon1,lon2]"
# It returns a String.
sub toJSON {
	my $self = $_[0];
	return '[' . $self->lat1() . ', ' . $self->lat2() . ', ' . $self->lon1() . ', ' . $self->lon2() . ']'
}


############################################################
####
####  (non-)Exportable Factory Functions (static, not OO methods)
####
############################################################

# factory sub to construct a new object given a HASH
# of parameters. If the 2nd parameter (destination) is left out,
# it will be created, therefore acting also as a "factory method".
# It returns the destination (which can be newly-created).
sub fromHash {
	my $src = $_[0];
	my $dst = $_[1] // Net::API::Nominatim::Model::BoundingBox->new();

	for ('lat1', 'lat2', 'lon1', 'lon2'){
		next unless exists($src->{$_}) && defined($src->{$_});
		$dst->{$_} = $src->{$_};
	}
	return $dst;
}

# factory sub to construct a new object given an ARRAY
# of ARRAYS of [lat,lon]
# If the 2nd parameter (destination) is left out,
# it will be created, therefore acting also as a "factory method".
# It returns the destination (which can be newly-created).
sub fromArrayOfArrays {
	my $src = $_[0];
	my $dst = $_[1] // Net::API::Nominatim::Model::BoundingBox->new();

	# AoA [[lat,lon][lat,lon]]
	my $idx = 0;
	for ('lat1', 'lon1', 'lat2', 'lon2'){
		my $i = int($idx / 2);
		my $j = $idx %2;
		$dst->{$_} = $src->[$i]->[$j];
		$idx++;
	}
	return $dst;
}

# factory sub to construct a new object given 1D ARRAY
# of [lat1, lat2, lon1, lon2] which is what Nominatim uses.
# If the 2nd parameter (destination) is left out,
# it will be created, therefore acting also as a "factory method".
# It returns the destination (which can be newly-created).
sub fromArray {
	my $src = $_[0];
	my $dst = $_[1] // Net::API::Nominatim::Model::BoundingBox->new();

	# A [lat1,lat2,lon1,lon2] /sic/
	my $idx = 0;
	for ('lat1', 'lat2', 'lon1', 'lon2'){
		$dst->{$_} = $src->[$idx++];
	}
	return $dst;
}

# factory sub to construct a new object given a JSON string
# of "[lat1, lat2, lon1, lon2]" as returned by a Nominatim search.
# If the 2nd parameter (destination) is left out,
# it will be created, therefore acting also as a "factory method".
# It returns the destination (which can be newly-created).
sub fromJSONArray {
	my $src = $_[0];
	my $dst = $_[1] // Net::API::Nominatim::Model::BoundingBox->new();

	# from JSON array of [lat1,lat2,lon1,lon2] /sic/
	# as a string
	my $p = json2perl($src);
	if( ! defined $p ){ print STDERR "${src}\n\n".__PACKAGE__."::fromJSONArray(), line ".__LINE__." : error, input parameter, assumed to be JSON but it does not validate, see above.\n"; return undef }
	return fromArray($p, $dst);
}

# factory sub to construct a new object with all random coordinates.
# Note that the 1st parameter (source) of the other 'from*' factory
# subs is unecessary and it is not preset.
# The 1st parameter is the destination and is optional.
# If the 1st parameter is left out,
# it will be created, therefore acting also as a "factory method".
# It returns the destination (which can be newly-created).
sub fromRandom {
	my $dst = $_[0] // Net::API::Nominatim::Model::BoundingBox->new();

	$dst->randomise();

	return $dst;
}

# It returns a random float in the range of
# EPSG:4326 Longitude coordinates
# see https://gis.stackexchange.com/questions/486800/generate-random-lon-lat-coordinate-anywhere-on-the-map
sub randomLon {
  return (rand() * 360.0) - 180.0
}
# It returns a random float in the range of
# EPSG:4326 Latitude coordinates
sub randomLat { return (_acos(2.0 * rand() - 1.0) * 170.12 / 3.14159265358979323846) - 85.06 }

sub _acos { atan2( sqrt(1 - $_[0] * $_[0]), $_[0] ) }

# the end

1;

=pod

=encoding utf8

=head1 NAME

Net::API::Nominatim::Model::BoundingBox - Storage class for the bounding box as returned by the Nominatim Service

=head1 VERSION

Version 0.03


=head1 DESCRIPTION

L<Net::API::Nominatim::Model::BoundingBox> is an OO module
which provides a class to store a generic 2-dimensional bounding box
comprising of two latitude/longitude coordinates
denoting its two opposite vertices, with assorted
constructor, getters, setters and stringifiers.

It can be constructed empty whereas all coordinates are set to C<0.0>,
or loaded with data passed in during construction.

=head1 SYNOPSIS

Example usage:

    use Net::API::Nominatim::Model::BoundingBox;

    # construct from a hash of parameters,
    # the keys must be exactly these:
    my $bbox = Net::API::Nominatim::Model::BoundingBox->new({
        lat1 => 30.12, lon1 => 12.22, lat2 => 30.15, lon2 => 12.5
    });

    # construct from a JSON string like the one used and returned
    # by Nominatim.
    my $bbox = Net::API::Nominatim::Model::BoundingBox->new(
        #  lat1, lat2,  lon1,  lon2
	"[30.12, 30.15, 12.22, 12.5]"
    );

    # construct from an ARRAY whose order is the same
    # as the one used and returned by Nominatim.
    my $bbox = Net::API::Nominatim::Model::BoundingBox->new(
        #  lat1, lat2,  lon1,  lon2
	[30.12, 30.15, 12.22, 12.5]
    );

    # construct from an ARRAY of ARRAYs of [lat,lon]
    my $bbox = Net::API::Nominatim::Model::BoundingBox->new(
        #  lat1, lon2,    lat2,  lon2
	[[30.12, 12.22], [30.15, 12.5]]
    );

    # print as the last example
    print $bbox->toString();

    # print as JSON like the one used by Nominatim
    print $bbox->toJSON();

    # additionally there are (non-)exportable factory subs
    # construct from a hash of parameters,
    # the keys must be exactly these:
    my $bbox = Net::API::Nominatim::Model::BoundingBox::fromHash({
        lat1 => 30.12, lon1 => 12.22, lat2 => 30.15, lon2 => 12.5
    });

    # construct from a JSON string like the one used and returned
    # by Nominatim.
    my $bbox = Net::API::Nominatim::Model::BoundingBox::fromJSONArray(
        #  lat1, lat2,  lon1,  lon2
	"[30.12, 30.15, 12.22, 12.5]"
    );

    # construct from an ARRAY whose order is the same
    # as the one used and returned by Nominatim.
    my $bbox = Net::API::Nominatim::Model::BoundingBox::fromArray(
        #  lat1, lat2,  lon1,  lon2
	[30.12, 30.15, 12.22, 12.5]
    );

    # construct from an ARRAY of ARRAYs of [lat,lon]
    my $bbox = Net::API::Nominatim::Model::BoundingBox::fromArrayOfArrays(
        #  lat1, lon2,    lat2,  lon2
	[[30.12, 12.22], [30.15, 12.5]]
    );

=head1 EXPORT

Nothing is exported because the sane choice for
sub names makes them too common thus a clash is imminent
or they must be of huge lengths in order to ensure
uniqueness. TLDR, use the fully qualified sub name,
like C<Net::API::Nominatim::Model::BoundingBox::fromRandom()>.


=head1 METHODS

=head2 new

The constructor can take zero or one parameters.
If zero, then the returned object contains C<0.0> for
all coordinates.

The optional parameter can be:

=over 2

=item * an ARRAY_REF of C<[lat1, lat2, lon1, lon2]>. The specific
order is what the actual
L<Nominatim|https://nominatim.openstreetmap.org/search>
service returns.

=item * an ARRAY_REF of arrays of C<[lat,lon]>, e.g.
C<[ [lat1,lon1], [lat2,lon2] ]>.

=item * a HASH_REF which must contain one to four items
keyed on C<lat1, lat2, lon1, lon2>. Values for whatever missing
keys will be set to C<0.0>.

=item * a JSON string of C<"[lat1, lat2, lon1, lon2]">.
The specific order is what the actual 
L<Nominatim|https://nominatim.openstreetmap.org/search> 
service returns.

=back

=head3 RETURN

The constructor will return C<undef> on failure
which can happen only if the input JSON string specified
does not validate as JSON.

=head2 lat1

Setter and Getter for the latitude C<lat1> of the first vertex of the bounding box.

=head2 lat2

Setter and Getter for the longitude C<lon1> of the first vertex of the bounding box.

=head2 lon1

Setter and Getter for the latitude C<lat2> of the second vertex of the bounding box.

=head2 lon2

Setter and Getter for the longitude C<lon2> of the second vertex of the bounding box.

=head2 toString

It returns the bounding box as this string C<"[ [lat1,lon1], [lat2,lon2] ]">.

=head2 toJSON

It returns the bounding box as this JSON string C<"[ lat1, lat2, lon1, lon2 ]">.

=head2 clone

It returns a totally new L<Net::API::Nominatim::Model::BoundingBox> object
deep-cloned from current object.

=head2 equals

It compares current object to the input object and returns 1 if they are equal
or 0 if they are not. Missing values (which are blank strings or undef objects)
will also count in the comparison.

=head1 AUTHOR

Andreas Hadjiprocopis, C<< <bliako at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-api-nominatim-model-boundingbox at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-API-Nominatim-Model-BoundingBox>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::API::Nominatim::Model::BoundingBox


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-API-Nominatim-Model-BoundingBox>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Net-API-Nominatim-Model-BoundingBox>

=item * Search CPAN

L<https://metacpan.org/release/Net-API-Nominatim-Model-BoundingBox>

=item * PerlMonks!

L<https://perlmonks.org/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by Andreas Hadjiprocopis.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Net::API::Nominatim::Model::BoundingBox

