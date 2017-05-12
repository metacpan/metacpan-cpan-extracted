###
# Copyright (c) 2004 Matthias Hilbig <bighil@cpan.org>
# All rights reserved.
# 
# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.
#

package Net::IPP::IPPAttribute;

use strict;
use warnings;

use Carp;

use Net::IPP::IPP qw(:all);

require Exporter;
our @ISA = ("Exporter");
our @EXPORT_OK = qw(encodeAttribute decodeAttribute);
our %EXPORT_TAGS = ( 'all' => \@EXPORT_OK );

# this variable is set to 1 by IPPRequest.pm to turn HP Bugfixing on
#
# one of the HP printers encodes the values of NAME_WITH_LANGUAGE and 
# TEXT_WITH_LANGUAGE types wrong:
#
# rfc conform encoding:
# val_length[lang_length[lang]name_length[name]]
#
# HP uses instead:
# lang_length[lang]name_length[name]
#

our $HP_BUGFIX = 0;

#
# Hash which associates attribute names with default IPP type.
# This default type can be overwritten with hash notation:
#
# "requesting-user-name" => { &TYPE => &NAME_WITH_LANGUAGE,
#                             &VALUE => "de, root" }
#
# TODO: enter all attributes that can be used in IPP requests
my %attributeTypes = (

	# operation attributes belong into the operation group

	"attributes-charset" => &CHARSET,
	"attributes-natural-language" => &NATURAL_LANGUAGE,
	"printer-uri" => &URI,
	"which-jobs" => &KEYWORD,
	"job-uri" => &URI,
	"job-id" => &INTEGER,
	"requesting-user-name" => &NAME_WITHOUT_LANGUAGE,
	"document-format" => &MIME_MEDIA_TYPE,
	"document-name" => &NAME_WITHOUT_LANGUAGE,
	"requested-attributes" => &KEYWORD,
	"limit" => &INTEGER,
	"printer-info" => &TEXT_WITHOUT_LANGUAGE,
	"printer-location" => &TEXT_WITHOUT_LANGUAGE,
	"printer-type" => &ENUM,
	
	# job-template-attributes
     "job-priority" => &INTEGER,
     "job-hold-until" => &KEYWORD,
	 "job-sheets" => &KEYWORD,
	 "multiple-document-handling" => &KEYWORD,
	 "copies" => &INTEGER,
	 "finishings" => &ENUM,
	 "page-ranges" => &RANGE_OF_INTEGER,
	 "sides" => &KEYWORD,
	 "number-up" => &INTEGER,
	 "orientation-requested" => &ENUM,
	 "media" => &KEYWORD,
	 "media-ready" => &KEYWORD,
	 "printer-resolution" => &RESOLUTION,
	 "print-quality" => &ENUM,

);

###
# Encode attribute to bytes.
#
# Parameters: $name  - name of attribute
#             $value - value of attribute
#
# Return: byte encoded attribute
#
sub encodeAttribute($$) {
	my $name = shift;	
	my $value = shift;
	
	my $type;
	if (ref($value) eq "HASH") {
		#if value is hashref, overwrite default IPP type
		if (exists($value->{&TYPE})) {
			$type = $value->{&TYPE};
		}
		if (!exists($value->{&VALUE})) {
			confess "Could not find value in Hash.\n";
		} else {
			$value = $value->{&VALUE};
		}		
	}
	
	if (!$type) {
		if (exists($attributeTypes{$name})) {
			$type = $attributeTypes{$name};	
		} else {
			# look if template attribute and then use type of base type
			my $base;
			if ($name =~ /^(.*)\-(default|supported)$/) {
				$base = $1;
			}
			if (exists($attributeTypes{$base})) {
				$type = $attributeTypes{$name};
			} else {
				confess "Error: Unknown attribute $name used in request.";			
			}		
		}
		
		
	}

    my $bytes = "";
	
	if (ref($value) eq "ARRAY") {
		#if value is arrayref encode isSet
		
		my $size = scalar(@{$value});
		for (my $i = 0; $i < $size; $i++) {
			$bytes .= pack("C", $type);
			my $tValue = transformValue($type, $name, $value->[$i], 0);
			if ($i == 0) {
				$bytes .= pack("n/a*n/a*", $name, $tValue); 
			} else {
		    	$bytes .= pack("nn/a*",0,$tValue);
			}
		}
	} else {
		#normal encoding
		$bytes .= pack("C", $type);
	    $value = transformValue($type, $name, $value, 0);
    	$bytes .= pack("n/a*n/a*", $name, $value);
	}

	return $bytes;
}

###
# Transforms attribute value, two modes are available: encoding and decoding
#
# Parameter: $type   - IPP type to use
#            $value  - value to transform
#            $decode - 1 for decoding, 0 for encoding
#
# Return: transformed value
#
sub transformValue($$$$) {
	my $type = shift;
	my $key = shift;
	my $value = shift;
	my $decode = shift;
	
	if ($type == &TEXT_WITHOUT_LANGUAGE 
			|| $type == &NAME_WITHOUT_LANGUAGE) {
				#RFC:  textWithoutLanguage,  LOCALIZED-STRING.
				#RFC:  nameWithoutLanguage
				return $value;
	} elsif ($type == &TEXT_WITH_LANGUAGE 
			|| $type == &NAME_WITH_LANGUAGE) {
				#RFC:  textWithLanguage      OCTET-STRING consisting of 4 fields:
				#RFC:                          a. a SIGNED-SHORT which is the number of
				#RFC:                             octets in the following field
				#RFC:                          b. a value of type natural-language,
				#RFC:                          c. a SIGNED-SHORT which is the number of
				#RFC:                             octets in the following field,
				#RFC:                          d. a value of type textWithoutLanguage.
				#RFC:                        The length of a textWithLanguage value MUST be
				#RFC:                        4 + the value of field a + the value of field c.
				if ($decode) {
					if ($IPPAttribute::HP_BUGFIX) {
						return $value;
					} else {
						my ($language, $text) = unpack("n/a*n/a*", $value);
						return "$language, $text";
					}
				} else {
					#TODO: test if HP needs bugfix also for encoding 
					$value =~ /^\s*([^,]*?)\s*,\s*([^,]*?)\s*$/;
					return pack("n/a*n/a*", $1, $2);
				}
	} elsif ($type == &CHARSET
			|| $type == &NATURAL_LANGUAGE
			|| $type == &MIME_MEDIA_TYPE
			|| $type == &KEYWORD
			|| $type == &URI
			|| $type == &URI_SCHEME) {
				#RFC:  charset,              US-ASCII-STRING.
				#RFC:  naturalLanguage,
				#RFC:  mimeMediaType,
				#RFC:  keyword, uri, and
				#RFC:  uriScheme
				return $value;
	} elsif ($type == &BOOLEAN) {
				#RFC:  boolean               SIGNED-BYTE  where 0x00 is 'false' and 0x01 is
				#RFC:                        'true'.
				if ($decode) {
					return unpack("c", $value);
				} else {
					if ($value) {
						return "\01";
					} else {
						return "\00";
					}
				}
	} elsif ($type == &INTEGER 
			|| $type == &ENUM) {
				#RFC:  integer and enum      a SIGNED-INTEGER.
				if ($decode) {
					return unpack("N", $value);
				} else {
					return pack("N", $value);
				}
	} elsif ($type == &DATE_TIME) {
				#RFC:  dateTime              OCTET-STRING consisting of eleven octets whose
				#RFC:                        contents are defined by "DateAndTime" in RFC
				#RFC:                        1903 [RFC1903].
				if ($decode) {
					my ($year, $month, $day, $hour, $minute, $seconds, $deciSeconds, $direction, $utcHourDiff, $utcMinuteDiff) 
						= unpack("nCCCCCCaCC", $value);
					return "$month-$day-$year,$hour:$minute:$seconds.$deciSeconds,$direction$utcHourDiff:$utcMinuteDiff";
				} else {
					if ($value =~ /^\s*(\d+)\s*-\s*(\d+)\s*-\s*(\d+)\s*,\s*(\d+)\s*:\s*(\d+)\s*:\s*(\d+)\s*.\s*(\d+)\s*,\s*([\-\+])\s*(\d+)\s*:\s*(\d+)\s*$/) {
						return pack("nCCCCCCaCC", $3, $1, $2, $4, $5, $6, $7, $8, $9, $10);
					} else {
						carp("Unable to parse date: $value");
						return "\00" x 8 . "+" . "\00\00";
					}
				}
	} elsif ($type == &RESOLUTION) {
				#RFC:  resolution            OCTET-STRING consisting of nine octets of  2
				#RFC:                        SIGNED-INTEGERs followed by a SIGNED-BYTE. The
				#RFC:                        first SIGNED-INTEGER contains the value of
				#RFC:                        cross feed direction resolution. The second
				#RFC:                        SIGNED-INTEGER contains the value of feed
				#RFC:                        direction resolution. The SIGNED-BYTE contains
				#RFC:                        the units				
				#                        unit: 3 = dots per inch
				#                              4 = dots per cm
				if ($decode) {
					my ($crossFeedResolution, $feedResolution, $unit)  = unpack("NNc", $value);
					my $unitText;
					if ($unit == 3) {
						$unitText = "dpi";
					} elsif ($unit == 4) {
						$unitText = "dpc";
					} else {
						carp ("Unknown Unit value: $unit");
						$unitText = $unit;
					}
					return "$crossFeedResolution, $feedResolution $unitText";
				} else {
					my ($crossFeedResolution, $feedResolution, $unitText) = 
					$value =~ /^\s*(\d+)\s*,\s*(\d+)\s*(\w+)\s*$/;
					my $unit;
					if ($unitText eq "dpi") {
						$unit = 3;
					} elsif ($unitText eq "dpc") {
						$unit = 4;
					} else {
						carp ("Unknown Unit: $unitText using dpi instead.");
						$unit = 3;
					}
					return pack("NNc", $crossFeedResolution, $feedResolution, $unit);
				}
	} elsif ($type == &RANGE_OF_INTEGER) {
				#RFC:  rangeOfInteger        Eight octets consisting of 2 SIGNED-INTEGERs.
				#RFC:                        The first SIGNED-INTEGER contains the lower
				#RFC:                        bound and the second SIGNED-INTEGER contains
				#RFC:                        the upper bound.
				if ($decode) {
					my ($lowerBound, $upperBound) = unpack("NN", $value);
					return "$lowerBound:$upperBound";
				} else {
					my ($lowerBound, $upperBound) = 
					$value =~ /^\s*(\d+)\s*:\s*(\d+)\s*$/;
					return pack("NN", $lowerBound, $upperBound);
				}
	} elsif ($type == &OCTET_STRING) {
				#RFC:  octetString           OCTET-STRING
				return $value;
	} elsif ($type == &BEG_COLLECTION) {
		if ($key) {
			carp "WARNING: Collection Syntax not supported. Attribute \"$key\" will have invalid value.\n";
		}
	} elsif ($type == &END_COLLECTION
	      || $type == &MEMBER_ATTR_NAME) {
		return $value;
	} else {
		carp "Unknown Value type ", sprintf("%#lx",$type) , " for key \"$key\". Performing no transformation.";
		return $value;
	}
}

###
# print warning if the key does not consist of word symbols and -, as 
# then something went probably wrong.
#
# Parameter: $key - attribute key to test
#
sub testKey($) {
	my $key = shift;
	if (not $key =~ /^[\w\-]*$/) {
		carp ("Probably wrong attribute key: $key\n");
	}
}

###
# test if response is RFC conform: if lengths of key or value is 
# longer than remaining bytes, something went wrong while decoding.
# 
# As there are (hopefully :-)) no bugs in the decoding functions, the response 
# is not RFC conform. 
#
# TODO: maybe implement length check for different attribute types:
#  maximum lengths of the different types:
#   'textWithLanguage          <= 1023 AND 'naturalLanguage' <= 63
#   'textWithoutLanguage'      <= 1023
#   'nameWithLanguage'         <= 255 AND 'naturalLanguage'  <= 63
#   'nameWithoutLanguage'      <= 255
#   'keyword'                  <= 255
#   'enum'                     = 4
#   'uri'                      <= 1023
#   'uriScheme'                <= 63
#   'charset'                  <= 63
#   'naturalLanguage'          <= 63
#   'mimeMediaType'            <= 255
#   'octetString'              <= 1023
#   'boolean'                  = 1
#   'integer'                  = 4
#   'rangeOfInteger'           = 8
#   'dateTime'                 = 11
#   'resolution'               = 9
#   '1setOf X'
#
sub testLengths($$) {
	use bytes;
	
	my $bytes = shift;
	my $offset = shift;

	my $keyLength = unpack("n", substr($bytes, $offset, 2));
	
	if ($offset + 2 + $keyLength > length($bytes)) {
		my $dump = bytesToString($bytes);
		print STDERR "---IPP RESPONSE DUMP (current offset: $offset):---\n$dump\n";
		confess("ERROR: IPP response is not RFC conform.");
	}
	
	my $valueLength = unpack("n", substr($bytes, $offset + 2 + $keyLength, 2));
	
	if ($offset + 4 + $keyLength + $valueLength > length($bytes)) {
		my $dump = bytesToString($bytes);
		print STDERR "---IPP RESPONSE DUMP (current offset: $offset):\n---$dump\n";
		confess("ERROR: IPP response is not RFC conform.");
	}
}

###
# Decode next attribute from IPP Response
#
# Parameters: $bytes     - IPP Response
#             $offsetref - reference to current position in IPP Response
#             $type      - type of attribute
#             $group     - reference to group into which to insert the attribute
#

my $previousKey; # used for 1setOf values

sub decodeAttribute($$$$) {
	my $bytes = shift;
	my $offsetref = shift;
	my $type = shift;
	my $group = shift;

	my $data;
	{ use bytes;
	$data = substr($bytes, $$offsetref);
	}
	
	my ($key, $value, $addValue);
	
	#TODO: novalue
	
	# HP BUG!!!!
	if ($IPPAttribute::HP_BUGFIX && ($type == &TEXT_WITH_LANGUAGE 
		|| $type == &NAME_WITH_LANGUAGE)) {
		($key, $value, $addValue) = unpack("n/a* n/a* n/a*", $data);
		
		testKey($key);
		
		{ use bytes;
		$$offsetref +=  6 + length($key) + length($value) + length($addValue);
		}
		
		$value .= ", " . $addValue;
	} else {
		
		testLengths($bytes, $$offsetref);
		
		($key, $value) = unpack("n/a* n/a*", $data);
		
		testKey($key);
		
		{ use bytes;
		$$offsetref += 4 + length($key) + length($value);
		}
	}
	
	#for attribute autodetection:
	if (&DEBUG) {
		if (!exists($attributeTypes{$key})) {
			print "Unknown attribute in response:\n";
			print "\"$key\" => $type\n"; 
		} elsif($attributeTypes{$key} != $type) {
			print "Attribute has unexpected type (instead of ",$attributeTypes{$key},"):\n";
			print "\"$key\" => $type\n";
		}
	}
	
	$value = transformValue($type, $key, $value, 1);
	 	
	# if key empty, attribute is 1setOf
	if (!$key) {
		if (!ref($group->{$previousKey})) {
			my $arrayref = [$group->{$previousKey}];
			$group->{$previousKey} = $arrayref;
		} 
		push @{$group->{$previousKey}}, $value;
	} else {
		$group->{$key} = $value;
		$previousKey = $key;
	}
}

1;
