
package PRANG::XMLSchema::Types;
$PRANG::XMLSchema::Types::VERSION = '0.20';
use strict;
use warnings;
use Moose::Util::TypeConstraints;

subtype "PRANG::XMLSchema::normalizedString"
	=> as "Str"
	=> where { !m{[\n\r\t]} };

subtype "PRANG::XMLSchema::token"
	=> as "Str"
	=> where {
	!m{[\t\r\n]|^\s|\s$|\s\s};
	};

# automatically trim tokens if passed them.
coerce "PRANG::XMLSchema::token"
	=> from "Str",
	=> via {
	my ($x) = m/\A\s*(.*?)\s*\Z/;
	$x =~ s{\s+}{ }g;
	$x;
	},
	;

# See https://rt.cpan.org/Ticket/Display.html?id=52309
# use Regexp::Common qw/URI/;
subtype "PRANG::XMLSchema::anyURI"
	=> as "Str"
	=> where {
	m{^\w+:\S+$};  # validate using this instead
	};

use I18N::LangTags qw(is_language_tag);
subtype "PRANG::XMLSchema::language"
	=> as "Str"
	=> where {
	is_language_tag($_);
	};

subtype "PRANG::XMLSchema::dateTime"
	=> as "Str"
	=> where {

	# from the XMLSchema spec... it'll do for now ;)
	# how on earth is one supposed to encode Pacific/Guam
	# or Pacific/Saipan dates before 1845 with this regex?
	m{
^
-?([1-9][0-9]{3,}|0[0-9]{3})
-(0[1-9]|1[0-2])
-(0[1-9]|[12][0-9]|3[01])
T(([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9](\.[0-9]+)?|(24:00:00(\.0+)?))
(?:Z|(?:\+|-)(?:(?:0[0-9]|1[0-3]):[0-5][0-9]|14:00))?
$
	 }x;
	};

subtype "PRANG::XMLSchema::time"
	=> as "Str"
	=> where {

	# from the XMLSchema spec... it'll do for now ;)
	m{
^
(([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9](\.[0-9]+)?|(24:00:00(\.0+)?))
(?:Z|(?:\+|-)(?:(?:0[0-9]|1[0-3]):[0-5][0-9]|14:00))?
$
	 }x;
	};

subtype "PRANG::XMLSchema::date"
	=> as "Str"
	=> where {

	# from the XMLSchema spec... it'll do for now ;)
	# XXX: Note, since the XML Spec bizarrely has Timezones on Dates,
	# we have chosen to ignore it (since it is optional anyway)
	m{
^
-?([1-9][0-9]{3,}|0[0-9]{3})
-(0[1-9]|1[0-2])
-(0[1-9]|[12][0-9]|3[01])
$
	 }x;
	};

subtype "PRANG::XMLSchema::duration"
	=> as "Str"
	=> where {
	m{^\s* (?: [pP]? \s* )?
		       (?: C \s* \d+)?
		       (?: Y \s* \d+)?
		       (?: M \s* \d+)?
		       (?: D \s* \d+)?
		       (?: h \s* \d+)?
		       (?: m \s* \d+)?
		       (?: s \s* \d+(?:\.\d+) )? \s* $}x;
	};

# other built-in primitive datatypes.
subtype "PRANG::XMLSchema::string"
	=> as "Str";
subtype "PRANG::XMLSchema::boolean"
	=> as "Str"
	=> where {
	m/^(?:0|1|true|false)$/;
	};
coerce "Bool"
	=> from 'PRANG::XMLSchema::boolean'
	=> via { m{1|true} ? 1 : 0 };
subtype "PRANG::XMLSchema::decimal"
	=> as "Num";

# floating point stuff...
subtype "PRANG::XMLSchema::float"
	=> as "Str"
	=> where {
	m{^(?:[\-+]?(?:\d+(?:\.\d*)?(?:e[\-+]?(\d+))?|inf)|NaN)$}i;
	};
our $inf = exp(~0 >> 1);
our $nan = $inf / $inf;
our $neg_inf = -$inf;
coerce "Num"
	=> from 'PRANG::XMLSchema::float'
	=> via {
	m{^(?:([\-+])?inf|(nan)|(.))};
	return eval $_ if defined $3;
	return $nan if $2;
	return $neg_inf if $1 and $1 eq "-";
	return $inf;
	};

if ( 0.1 == 0.100000000000000006 ) {
	subtype "PRANG::XMLSchema::double"
		=> as "PRANG::XMLSchema::float";
}
else {
	subtype "PRANG::XMLSchema::double"
		=> as "PRANG::XMLSchema::float"
		=> where {
		unpack('d',pack('d',$_))==$_;
		};

	coerce "PRANG::XMLSchema::double"
		=> from "PRANG::XMLSchema::float"
		=> via {
		unpack('d',pack('d',$_));
		};
}

# built-in derived types.
# this sub-typing might seem unnecessarily deep, but that's what the
# spec says... see http://www.w3.org/TR/2004/REC-xmlschema-2-20041028/datatypes.html#built-in-derived
subtype "PRANG::XMLSchema::integer"
	=> as "Int";
subtype "PRANG::XMLSchema::nonPositiveInteger"
	=> as "PRANG::XMLSchema::integer"
	=> where {
	$_ <= 0;
	};
subtype "PRANG::XMLSchema::negativeInteger"
	=> as "PRANG::XMLSchema::nonPositiveInteger"
	=> where {
	$_ <= -1;
	};
subtype "PRANG::XMLSchema::nonNegativeInteger"
	=> as "PRANG::XMLSchema::integer"
	=> where {
	$_ >= 0;
	};
subtype "PRANG::XMLSchema::positiveInteger"
	=> as "PRANG::XMLSchema::nonNegativeInteger"
	=> where {
	$_ >= 1;
	};
subtype "PRANG::XMLSchema::long"
	=> as "PRANG::XMLSchema::integer"
	=> where {
	$_ >= -9223372036854775808 and $_ <= 9223372036854775807;
	};
subtype "PRANG::XMLSchema::int"
	=> as "PRANG::XMLSchema::long"
	=> where {
	$_ >= -2147483648 and $_ <= 2147483647;
	};
subtype "PRANG::XMLSchema::short"
	=> as "PRANG::XMLSchema::int"
	=> where {
	$_ >= -32768 and $_ <= 32767;
	};
subtype "PRANG::XMLSchema::byte"
	=> as "PRANG::XMLSchema::short"
	=> where {
	$_ >= -128 and $_ <= 127;
	};
subtype "PRANG::XMLSchema::unsignedLong"
	=> as "PRANG::XMLSchema::nonNegativeInteger"
	=> where {
	$_ >= 0 and $_ < 18446744073709551615;
	};
subtype "PRANG::XMLSchema::unsignedInt"
	=> as "PRANG::XMLSchema::unsignedLong"
	=> where {
	$_ >= 0 and $_ < 2147483647;
	};
subtype "PRANG::XMLSchema::unsignedShort"
	=> as "PRANG::XMLSchema::unsignedInt"
	=> where {
	$_ >= 0 and $_ < 65536;
	};
subtype "PRANG::XMLSchema::unsignedByte"
	=> as "PRANG::XMLSchema::unsignedShort"
	=> where {
	$_ >= 0 and $_ < 256;
	};

1;

=head1 NAME

PRANG::XMLSchema::Types - type registry for XML Schema-related types

=head1 SYNOPSIS

 package My::Class;
 use Moose;
 use PRANG::Graph;
 use PRANG::XMLSchema::Types;

 has_attr 'foo' =>
    is => "ro",
    isa => "PRANG::XMLSchema::unsignedShort",
    ;

=head1 DESCRIPTION

This module is a collection of types which make working with XML
Schema specifications easier.  See the source for the complete list.

These might be moved into a separate namespace, but if you include
this module you will get aliases for wherever these XML Schema types
end up.

=head1 SEE ALSO

L<PRANG>, L<PRANG::Graph::Meta::Attr>, L<PRANG::Graph::Meta::Element>

=head1 AUTHOR AND LICENCE

Development commissioned by NZ Registry Services, and carried out by
Catalyst IT - L<http://www.catalyst.net.nz/>

Copyright 2009, 2010, NZ Registry Services.  This module is licensed
under the Artistic License v2.0, which permits relicensing under other
Free Software licenses.

=cut

