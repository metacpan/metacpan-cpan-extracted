package Net::API::Nominatim::Model::Address;

use strict;
use warnings;

our $VERSION = '0.03';

use Data::Structure::Util qw/unbless/;
use Data::Roundtrip qw/perl2dump json2perl perl2json no-unicode-escape-permanently/;

use Net::API::Nominatim::Model::BoundingBox;

# export nothing otherwise we need to adjust our sub names
# to avoid clashes, e.g. fromHash, use these like
#   Net::API::Nominatim::Model::Address::fromHash()

#use Exporter;
#our (@EXPORT_OK, %EXPORT_TAGS);
#BEGIN {
#	@EXPORT_OK = qw/
#		fromHash fromArray fromJSONHash
#		fromJSONArray
#	/;
#	%EXPORT_TAGS = ( all => [@EXPORT_OK] );
#}

sub new {
	my ($class, $params) = @_;

	my $self = {
		'place_id' => '',
		'osm_type' => '',
		'osm_id' => '',
		'lat' => '',
		'lon' => '',
		'name' => '',
		'type' => '',
		'place_rank' => '',
		'boundingbox' => undef,
		'category' => '',
		'addresstype' => '',
		'importance' => '',
		'display_name' => '',
		'licence' => '',
	};
	bless $self => $class;
	return $self unless defined $params;

	if( ref($params)eq'HASH' ){
		fromHash($params, $self);
	} elsif( ref($params)eq'' ){
		if( ! defined fromJSONHash($params, $self) ){ print STDERR __PACKAGE__."->new(), line ".__LINE__." : error, input JSON string was malformed, failed.\n"; return undef }
	} elsif( ref($params) eq __PACKAGE__ ){
		fromHash($params->toHash(), $self);
	}
	return $self;
}

###########################################
# getters and setters at the same time
#
sub fields { return sort keys %{$_[0]} }
sub place_id { return $_[1] ? $_[0]->{place_id} = $_[1] : $_[0]->{place_id} }
sub osm_type { return $_[1] ? $_[0]->{osm_type} = $_[1] : $_[0]->{osm_type} }
sub osm_id { return $_[1] ? $_[0]->{osm_id} = $_[1] : $_[0]->{osm_id} }
sub lat { return $_[1] ? $_[0]->{lat} = $_[1] : $_[0]->{lat} }
sub lon { return $_[1] ? $_[0]->{lon} = $_[1] : $_[0]->{lon} }
sub name { return $_[1] ? $_[0]->{name} = $_[1] : $_[0]->{name} }
sub type { return $_[1] ? $_[0]->{type} = $_[1] : $_[0]->{type} }
sub place_rank { return $_[1] ? $_[0]->{place_rank} = $_[1] : $_[0]->{place_rank} }
sub boundingbox { return $_[1] ? $_[0]->{boundingbox} = $_[1] : $_[0]->{boundingbox} }
sub category { return $_[1] ? $_[0]->{category} = $_[1] : $_[0]->{category} }
sub addresstype { return $_[1] ? $_[0]->{addresstype} = $_[1] : $_[0]->{addresstype} }
sub importance { return $_[1] ? $_[0]->{importance} = $_[1] : $_[0]->{importance} }
sub display_name { return $_[1] ? $_[0]->{display_name} = $_[1] : $_[0]->{display_name} }
sub licence { return $_[1] ? $_[0]->{licence} = $_[1] : $_[0]->{licence} }

# randomise all fields of CURRENT object to random strings
# (see randomString(length) on how this is done).
# By default empty and undef fields will not be randomised.
# Unless optional 2nd parameter is set to 1. Default is 0.
# It will/can also randomise the boundingbox object.
sub randomise {
	my $self = $_[0];
	# if a value is undef, shall we keep it as undef or randomise it, including the objects
	# the empty strings included
	my $keepUndefAndEmpty = $_[1] // 0;

	# all the fields except 'boundingbox'
	for(grep {$_ ne 'boundingbox'} $self->fields){
		$self->{$_} = randomString(5 + int(rand(5)));
	}
	# the boundingbox
	if( exists($self->{boundingbox}) && defined($self->{boundingbox}) ){
		$self->{boundingbox}->randomise();
	} elsif( $keepUndefAndEmpty > 0 ){
		$self->{boundingbox} = Net::API::Nominatim::Model::BoundingBox::fromRandom();
		if( ! defined $self->{boundingbox} ){ print STDERR __PACKAGE__."::fromRandom(): error, call to ".'Net::API::Nominatim::Model::BoundingBox::fromRandom()'." has failed.\n"; return undef }
	}
	return $self;
}

# Clone current object and return the new one.
# It can return undef on failure.
sub clone { return Net::API::Nominatim::Model::Address->new($_[0]->toHash()) }

# It checks equality between our current object and the
# second object passed as the input parameter.                 
# It returns 1 if equal, 0 if not,
# it first checks if the types of objects are the same.
# It also checks if the boundingbox object are the same,
# including whether they are defined or not.
sub equals {
	my ($x, $y) = @_;
	return 0 unless ref($x) eq ref($y); # not same object type
	return 1 if "$x" eq "$y"; # same pointer

	LL:
	for($x->fields){
		if( $_ eq 'boundingbox' ){
			my $b1 = $x->$_(); my $b2 = $y->$_();
			my $d1 = defined($b1); my $d2 = defined($b2);
			return 0 if $d1 ^ $d2;
			if( $d1 && $d2 ){ return 0 unless $b1->equals($b2); }
		} else {
			return 0 unless $x->{$_} eq $y->{$_};
		}
	}
	return 1 # equal
}

# It returns the current object as a HASH_REF,
# including the contained boundingbox object
sub toHash {
	my $self = $_[0];
	# !shhh!
	my $bb = $self->boundingbox(); $self->boundingbox(undef);
	my $p = { %$self }; # <<<< WARNING, provided we ONLY HAVE SCALARS (except the bounding box)
	$p->{boundingbox} = defined($bb) ? $bb->toArray() : undef;
	$self->boundingbox($bb);
	return $p; # ouph!
}

# Stringify the current object, including the contained
# boundingbox object.
# This is the same as toJSON().
# CAVEAT: the only problem is
# that the bounding box will not be a 2D array but 1D like all Nominatim
# TODO: if you care you can fix it.
# The return string is valid JSON string and can be used
# to "rehydrate" an object.
# It will return undef on failure.
sub toString { return $_[0]->toJSON() }

# It returns a JSON string containing a hash (the current Address object),
# including the boundingbox object.
# It will return undef on failure.
sub toJSON {
	my $self = $_[0];
	my $p = $self->toHash();
	my $ret = perl2json($p);
	if( ! defined $ret ){ print STDERR perl2dump($p).__PACKAGE__."::toJSON(), line ".__LINE__." : error, failed to convert above perl structure to JSON.\n"; return undef }
	return $ret;
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
	my $dst = $_[1] // Net::API::Nominatim::Model::Address->new();

	# all the fields except 'boundingbox'
	for(grep {$_ ne 'boundingbox'} $dst->fields){
		next unless exists($src->{$_}) && defined($src->{$_});
		$dst->{$_} = $src->{$_};
	}
	# the boundingbox
	if( exists($src->{boundingbox}) && defined($src->{boundingbox}) ){
		$dst->{boundingbox} = Net::API::Nominatim::Model::BoundingBox->new(
			$src->{boundingbox}
		);
		if( ! defined($dst->{boundingbox}) ){ print STDERR perl2dump($src->{boundingbox}).__PACKAGE__."::fromHash(), line ".__LINE__." : error, failed to clone the BoundingBox above.\n"; return undef }
	}
	return $dst;
}

# factory sub to return an ARRAY of new objects given an Array of
# Hashes, each containing fields for a single address.
# If the 2nd parameter (destination) is left out,
# it will be created AS AN ARRAY, therefore acting also as a "factory method".
# It returns the destination (which can be newly-created).
sub fromArray {
	my $src = $_[0];
	my $dst = $_[1] // [];

	for my $pana (@$src){
		my $h = fromHash($pana);
		if( ! defined $h ){ print STDERR __PACKAGE__."::fromHash(), line ".__LINE__." : error, call to ".'fromHash()'." has failed for an address item, part of the input ARRAY of addresses.\n"; return undef }
		push @$dst, $h;
	}
	return $dst;
}

# factory sub to construct a new object given a JSON string
# containing a HASH represeting a single address, like
# "{street: etc. ...}".
# '/reverse' returns a JSON hash and this sub can be used to decode it
# '/search' returns a JSON ARRAY (many addresses) and fromJSONArray()
# should be used in this case.
# If the 2nd parameter (destination) is left out,
# it will be created, therefore acting also as a "factory method".
# It returns the destination (which can be newly-created).
sub fromJSONHash {
	my $src = $_[0];
	my $dst = $_[1] // Net::API::Nominatim::Model::Address->new();

	# from JSON hash (as a string)
	my $p = json2perl($src);
	if( ! defined $p ){ print STDERR "${src}\n\n".__PACKAGE__."::fromJSONHash(), line ".__LINE__." : error, input parameter, assumed to be JSON but it does not validate, see above.\n"; return undef }
	if( ! defined fromHash($p, $dst) ){ print STDERR __PACKAGE__."::fromJSONHash(), line ".__LINE__." : error, call to ".'fromHash()'." has failed.\n"; return undef }
	return $dst;
}

# factory sub to return an ARRAY of new objects given a JSON string
# of "[ {name: ...}, {...}]" as returned by a Nominatim search.
# NOTE: Nominatim ALWAYS returns
# an array of hashes (array of addresss) so here we will
# do some convenience and return an array of addresses.
# If the 2nd parameter (destination) is left out,
# it will be created AS AN ARRAY, therefore acting also as a "factory method".
# It returns the destination (which can be newly-created).
sub fromJSONArray {
	my $src = $_[0];
	my $dst = $_[1] // [];

	# from JSON hash (as a string)
	my $p = json2perl($src);
	if( ! defined $p ){ print STDERR "${src}\n\n".__PACKAGE__."::fromJSONArray(), line ".__LINE__." : error, input parameter, assumed to be JSON but it does not validate, see above.\n"; return undef }
	if( ref($p) ne 'ARRAY' ){ print STDERR "${src}\n\n".__PACKAGE__."::fromJSONArray(), line ".__LINE__." : error, input JSON is not an ARRAY but '".ref($p)."', see above.\n"; return undef }
	for my $pana (@$p){
		my $h = fromHash($pana);
		if( ! defined $h ){ print STDERR __PACKAGE__."::fromJSONArray(), line ".__LINE__." : error, call to ".'fromHash()'." has failed for an address item, part of the input ARRAY of addresses.\n"; return undef }
		push @$dst, $h;
	}
	return $dst;
}

# factory sub to construct a new object from totally random values
# If the 1st parameter is left out,
# it will be created, therefore acting also as a "factory method".
# It returns the destination (which can be newly-created).
sub fromRandom {
	my $dst = $_[0] // Net::API::Nominatim::Model::Address->new();
	# all empty strings or undef will be randomised (0)
	if( ! defined $dst->randomise(0) ){ print STDERR __PACKAGE__."::fromRandom(), line ".__LINE__." : error, call to ".'randomise()'." has failed.\n"; return undef }
	return $dst;
}

sub randomString {
	return join('', map { [0..9,'A'..'F']->[rand 16] } 1..$_[0]);
}
1;
=pod

=encoding utf8

=head1 NAME

Net::API::Nominatim::Model::Address - Storage class for the address data as returned by the Nominatim Service

=head1 VERSION

Version 0.03


=head1 DESCRIPTION

Net::API::Nominatim::Model::Address provides a Class
for storing the address data as returned by Nominatim
search, with assorted
constructor, getters, setters and stringifiers.

It can be constructed empty whereas all fields will be set
to empty string and the bounding box set to C<undef>
or loaded with, possibly incomplete, data passed in during construction. Any
missing data will be set to empty strings except for
the bounding box which will be set to C<undef>.

=head1 SYNOPSIS

Example usage:

    use Net::API::Nominatim::Model::Address;

    my $address = Net::API::Nominatim::Model::Address->new({
	'lat' => ...
	'lon' => ...
	'name' => ...
	...
    });

    # or use the Random factory
    my $address = Net::API::Nominatim::Model::Address::fromRandom();

    # or use the JSON factory
    # this returns just a single address from a JSON hash
    # Nominatim's /reverse (for reverse geocoding) returns such JSON hash
    my $address = Net::API::Nominatim::Model::Address::fromJSONHash($jsonstr);

    # this returns an array of Address objects,
    # Nominatim's /search returns such JSON array-of-hashes
    my $addresses = Net::API::Nominatim::Model::Address::fromJSONArray($jsonstr);

    # stringify
    print $address->toString();

    # print as JSON string like the one returned by Nominatim's /search
    print $address->toJSON();

    # additionally there are (non-)exportable factory subs
    # construct from a hash of parameters,
    # the keys must be exactly these:
    my $address = Net::API::Nominatim::Model::Address::fromHash({
        ...
    });


=head1 EXPORT

Nothing is exported because the sane choice for
sub names makes them too common thus a clash is imminent
or they must be of huge lengths in order to ensure
uniqueness. TLDR, use the fully qualified sub name,
like C<Net::API::Nominatim::Model::Address::fromRandom()>.

=head1 METHODS

=head2 new

The constructor can take zero or one parameters.
If zero, then the returned object contains C<0.0> for
all coordinates.

The optional parameter can be:

=over 2

=item * a HASH_REF which must contain any of these fields
which are stored under this name internally.
Note that there are setters and getters for each of these fields.

=over 2

=item * C<place_id>

=item * C<osm_type>

=item * C<osm_id>

=item * C<lat>

=item * C<lon>

=item * C<name>

=item * C<type>

=item * C<place_rank>

=item * C<boundingbox>

=item * C<category>

=item * C<addresstype>

=item * C<importance>

=item * C<display_name>

=item * C<licence>

=back

All missing values will be set to a blank string. Except
for C<boundingbox> which will be left C<undef>.

=item * a JSON string containing just one hash which
represents just one Address with one or more fields
as outlined above. This JSON string is usually returned
by Nominatim's C</reverse>. Nominatim's C</search>
returns a JSON string of an array of hashes and you
can not use that here, obviously (hint: use factory method
L<fromJSONArray>).

=item * an L<Net::API::Nominatim::Model::Address> object
which we will clone it into the returned new Address object.

=back

=head3 RETURN

The constructor will return C<undef> on failure
which can happen only if the input JSON string specified
does not validate as JSON. It will not die.

=head2 C<toString>

C<print $address-E<gt>toString();>

It returns a stringified version of this object.

=head2 C<toJSON>

C<my $jsonstr = $address-E<gt>toJSON();>

It returns a JSON string containing a hash with all the fields of this object.

=head2 C<clone>

C<my $newaddress = $address-E<gt>clone();>

It returns a totally new L<Net::API::Nominatim::Model::Address> object
deep-cloned from current object.

=head2 C<equals>

C<my $yes = $address-E<gt>equals($anotheraddress);>

It compares current object to the input object and returns 1 if they are equal
or 0 if they are not. Missing values (which are blank strings or undef objects)
will also count in the comparison.

=head2 C<randomise>

C<$address-E<gt>randomise();>

It overwrites all fields with random strings, including those which were blank.
C<boundingbox> will also be randomised as per L<Net::API::Nominatim::Model::BoundingBox::randomise>.

=head2 fromHash 

C<my $address = Net::API::Nominatim::Model::Address::fromHash({...});>

Factory method to create a new L<Net::API::Nominatim::Model::Address> object
given an input C<HASH_REF> with one or more fields this object contains, mentioned
in the L<constructor|new>.

=head2 fromArray

C<my $addressesARRAY = Net::API::Nominatim::Model::Address::fromArray([{...},{...},...]);>

Factory method to create an C<ARRAY_REF> of L<Net::API::Nominatim::Model::Address> objects
given an input C<ARRAY_REF> in which each item is a C<HASH_REF> containing the data
for a single address. Its fields are mentioned
in the L<constructor|new>.

=head2 C<fields>

It returns all the fields stored in an L<Net::API::Nominatim::Model::Address> object
as an array.

=head2 C<place_id>

If a parameter is provided then it sets the value of field C<place_id> to it,
otherwise it returns the value of field C<place_id>.

=head2 C<osm_type>

If a parameter is provided then it sets the value of field C<osm_type> to it,
otherwise it returns the value of field C<osm_type>.

=head2 C<osm_id>

If a parameter is provided then it sets the value of field C<osm_id> to it,
otherwise it returns the value of field C<osm_id>.

=head2 C<lat>

If a parameter is provided then it sets the value of field C<lat> to it,
otherwise it returns the value of field C<lat>.

=head2 C<lon>

If a parameter is provided then it sets the value of field C<lon> to it,
otherwise it returns the value of field C<lon>.

=head2 C<name>

If a parameter is provided then it sets the value of field C<name> to it,
otherwise it returns the value of field C<name>.

=head2 C<type>

If a parameter is provided then it sets the value of field C<type> to it,
otherwise it returns the value of field C<type>.

=head2 C<place_rank>

If a parameter is provided then it sets the value of field C<place_rank> to it,
otherwise it returns the value of field C<place_rank>.

=head2 C<boundingbox>

If a parameter is provided then it sets the value of field C<boundingbox> to it,
otherwise it returns the value of field C<boundingbox>.

=head2 C<category>

If a parameter is provided then it sets the value of field C<category> to it,
otherwise it returns the value of field C<category>.

=head2 C<addresstype>

If a parameter is provided then it sets the value of field C<addresstype> to it,
otherwise it returns the value of field C<addresstype>.

=head2 C<importance>

If a parameter is provided then it sets the value of field C<importance> to it,
otherwise it returns the value of field C<importance>.

=head2 C<display_name>

If a parameter is provided then it sets the value of field C<display_name> to it,
otherwise it returns the value of field C<display_name>.

=head2 C<licence>

If a parameter is provided then it sets the value of field C<licence> to it,
otherwise it returns the value of field C<licence>.

=head1 AUTHOR

Andreas Hadjiprocopis, C<< <bliako at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-api-nominatim-model-boundingbox at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-API-Nominatim-Model-Address>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::API::Nominatim::Model::Address


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-API-Nominatim-Model-Address>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Net-API-Nominatim-Model-Address>

=item * Search CPAN

L<https://metacpan.org/release/Net-API-Nominatim-Model-Address>

=item * PerlMonks!

L<https://perlmonks.org/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by Andreas Hadjiprocopis.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Net::API::Nominatim::Model::Address

