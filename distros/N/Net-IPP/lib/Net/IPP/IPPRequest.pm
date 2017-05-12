###
# Copyright (c) 2004 Matthias Hilbig <bighil@cpan.org>
# All rights reserved.
# 
# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.
#
# Perl API for sending IPP requests
#
#    Uses: LWP::UserAgent
#          Carp
#
# Perl files: lib/Net/IPP/IPPRequest.pm   - main API file
#             lib/Net/IPP/IPPAttribute.pm - encodes/decodes IPP attributes
#             lib/Net/IPP/IPPUtil.pm      - helper functions
#             lib/Net/IPP/IPPMethods.pm   - ippRequest wrappers
#             lib/Net/IPP/IPP.pm          - contains all IPP constants
#             sample/ipptest.pl           - IPP lowlevel access example
#             sample/printerAttributes.pl - show IPP attributes of printer
#             sample/showJobs.pl          - show IPP jobs of printer
#             sample/monitorState.pl      - monitor Status of printer
#             sample/monitorJobs.pl       - monitor Status of jobs
#             t/codec.t                   - Testcases for encoding and
#                                           decoding of IPP requests
#             t/transform.t               - Testcases for transformValue
#                                           method
#    for Changes look at the Changes file.
#
#------------------------------------------------------------------------------

package Net::IPP::IPPRequest;

our $VERSION = "0.1";

#TODO: which perl version is required? Maybe 5.6 or something like that
#use 5.008;

use strict;
use warnings;

use Carp;
use LWP::UserAgent;

use Net::IPP::IPP qw(:all);
use Net::IPP::IPPAttribute qw(:all);
use Net::IPP::IPPUtil qw(:all);

require Exporter;
our @ISA = ("Exporter");
our @EXPORT_OK = qw(ippRequest);
our %EXPORT_TAGS = ( 'all' => \@EXPORT_OK );


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# ENCODING
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

###
# encode IPP Header
#
# Parameter: $operation - IPP operation
#            $requestId - id of IPP request
#
# Return: byte encoded IPP Header (length: 8 Byte)
#

sub encodeIPPHeader($$) {
  my $operation = shift;
  my $requestId = shift;
  print("Operation: $operation, RequestID: $requestId\n") if &DEBUG;
  return pack("CCnN",
		   &IPP_MAJOR_VERSION,
		   &IPP_MINOR_VERSION,
		   $operation,
		   $requestId
		  );
}


###
# encode an IPP group with all attributes
#
# Parameter: $attributes - reference to IPP attributes
#
# Return: byte encoding of attributes
#

# TODO: RFC requires ascending order of groups(Idea: test if type numbers of following groups are >= 
# previous group type)
sub encodeGroups($) {
  	my $attributes = shift;
  	my $bytes;
	
	if (!exists($attributes->{&TYPE})) {
		confess ("Type missing in group.");	
	}
	
  	$bytes = pack("C", $attributes->{&TYPE});
  	
  	#
	# "attributes-charset" must be first, "attributes-natural-language"
	# must be second attribute in operation group, also ignore
	# these two attributes in all groups except the operation group
	use constant att_charset => "attributes-charset";
	use constant att_language => "attributes-natural-language";

	if ($attributes->{&TYPE} == &OPERATION_ATTRIBUTES) {
		if (!exists($attributes->{att_charset})) {
			$bytes .= encodeAttribute(att_charset, "utf-8");
		} else {
			$bytes .= encodeAttribute(att_charset, $attributes->{att_charset});
		}
	
		if (!exists($attributes->{att_language})) {
			$bytes .= encodeAttribute(att_language, "en");
		} else {
			$bytes .= encodeAttribute(att_language, $attributes->{att_language});
		}
	}

	# encode all other attributes
	while (my ($key, $value) = each %{$attributes}) {
    	if ($key ne &TYPE
    		and $key ne att_charset
    		and $key ne att_language) {
    		$bytes .= encodeAttribute($key, $value);
    	}
  	}
  	return $bytes;
}


###
# convert an IPP Request from Perl encoding to Byte encoding
#
# Parameter: $request - IPP request
#
# Return: byte encoding of $request
#

sub hashToBytes($) {
  	my $request = shift;

	if (!exists($request->{&OPERATION}) || !exists($request->{&REQUEST_ID})) {
		confess("Operation or Request-ID is missing in request.");
	}

  	my $bytes = encodeIPPHeader($request->{&OPERATION}, $request->{&REQUEST_ID});

  	foreach my $group (@{$request->{&GROUPS}}) {
    	$bytes .= encodeGroups($group);
  	}

  	$bytes .= pack("C", &END_OF_ATTRIBUTES);

	printBytes($bytes) if &DEBUG;	
  	return $bytes;
}

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# DECODING
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

###
# decode IPPHeader to Perl encoding
#
# Parameter: $bytes - IPP response
#         $response - reference to hash for decoding
#
# Return: decoded values are returned in hash referenced by $response
#
sub decodeIPPHeader($$) {
	my $bytes = shift;
	my $response = shift;
	
	my $data;
	{use bytes; $data = substr($bytes,0,8);}
	
	my ($majorVersion, $minorVersion, $status, $requestId) = unpack("CCnN", $data);
	
	$response->{&VERSION} = $majorVersion . "." . $minorVersion;
	
	$response->{&STATUS} = $status;
	
	$response->{&REQUEST_ID} = $requestId;
}


###
# decode all IPP Groups from byte encoding to Perl encoding
#
# Parameter: $bytes - IPP response
#         $response - reference to hash for decoding
#
# Return: decoded values are returned in hash referenced by $response
#
sub decodeIPPGroups($$) {
	my $bytes = shift;
	my $response = shift;
	
	$response->{&GROUPS} = [];
		
	# begin directly after IPPHeader (length 8 byte)
	my $offset = 8;
	my $currentGroup = "";
	my $type;
	
	do {
		{
		use bytes;
		$type = ord(substr($bytes, $offset, 1));
		}
		
		$offset++;
				
		if (exists($Net::IPP::IPP::group{$type})) {
			print "group $type found\n" if &DEBUG;
			if ($currentGroup) {
				push @{$response->{&GROUPS}}, $currentGroup;
			}
			
			if ($type != &END_OF_ATTRIBUTES) {
				$currentGroup = {
					&TYPE => $type
				};
			}
		} elsif ($currentGroup eq "") {
			confess("Expected Group Tag at begin of IPP response.");
		} else {
			decodeAttribute($bytes, \$offset, $type, $currentGroup);
		}	
	} while ($type != &END_OF_ATTRIBUTES);
}

###
# Decode whole IPP response from byte encoding to perl encoding
#
# Parameter: $bytes - byte encoded IPP response
#         $response - reference to hash for decoding
#
# Return: decoded values are returned in hash referenced by $response
#

sub bytesToHash($$) {
	my $bytes = shift;
	my $response = shift;
		
	printBytes($bytes) if &DEBUG;
	
	decodeIPPHeader($bytes, $response);
	
	decodeIPPGroups($bytes, $response);
	
	return $response;
}

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# IPP Request
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

my $userAgent = LWP::UserAgent->new;
$userAgent->agent("Perl IPP API/$VERSION");

###
# Do the actual IPP request
#
# Parameter: $request - perl encoded IPP request
#
# Return: perl encoded IPP response
#

sub ippRequest($) {
	my $request = shift;
	if (!exists($request->{&URL})) {
		confess("Missed URL in request.");		
	}
	my $url = $request->{&URL};
	
	if (exists($request->{&HP_BUGFIX})) {
		$Net::IPP::IPPAttribute::HP_BUGFIX = $request->{&HP_BUGFIX};
	} else {
		$Net::IPP::IPPAttribute::HP_BUGFIX = 0;
	}

	#convert perl structure to IPP request
	my $content = hashToBytes($request);
	
	if (exists($request->{&DATA})) {
		$content .= $request->{&DATA};
	}	
	
	# use LWP to send HTTP Post request
	my $httpRequest = HTTP::Request->new(POST => "$url");
	$httpRequest->content_type('application/ipp');
	$httpRequest->content($content);
	my $result = $userAgent->request($httpRequest);
	
	my $response = {
		&HTTP_CODE => $result->code(),
		&HTTP_MESSAGE => $result->message(),
	};
	
	if ($result->is_success) {
		#printBytes($result->content);

		#convert response back to perl structure
		return bytesToHash($result->content, $response);
	} else {
		return $response;
	}
}

1;
__END__

=head1 NAME

Net::IPP::IPPRequest - Perl extension for IPP Requests

=head1 EXAMPLE

 use Net::IPP::IPPRequest qw(:all);
 my $request = {
                &URL => "http://localhost:631/printers/test",
                &REQUEST_ID => 1,
                &OPERATION => &IPP_GET_PRINTER_ATTRIBUTES,
                &GROUPS => [
                            {
                                &TYPE => &OPERATION_ATTRIBUTES,
                                "attributes-charset" => "utf-8",
                                "attributes-natural-language" => "en",
                                "printer-uri" => $url,
                            }
                           ]
               };   
 my $response = ippRequest($request);

=head1 INSTALLATION

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install

=head1 RUNNING TESTS

To run all tests in the t/ directory type the following:

   make test

For more details while running the tests type:

   make TEST_VERBOSE=1 test

=head1 RUNNING SAMPLES

After installation all programs in the sample directory should run
without problems. To run the sample programs without installing this
package use the blib module:

   perl Makefile.PL
   make
   cd samples
   perl -Mblib sampleprogram.pl [arguments]

=head1 STRUCTURE

              +------------+
              | IPPMethods |
              +------------+
                     ^
                     |
              +------------+
              | IPPRequest |
              +------------+
                     ^
                     |
       +-------------+---+-----------+
       |                 |           |
+--------------+    +---------+   +-----+
| IPPAttribute |    | IPPUtil |   | IPP |
+--------------+    +---------+   +-----+

=head1 WHAT TO DO, IF

=over 4

=item 1. You get the error "Error: Unknown attribute xyz used in request.":

The API did not find a default IPP type for attribute xyz in the hash Net::IPP::IPPAttribute::attributeTypes.

B<Method 1 (workaround):>
Look in [RFC 2911] which type attribute xyz has. It may
f.e. have the type XYZ. If you used something like 

               "xyz" => "value",

in the IPP request before, substitute that with
 
               "xyz" => { &TYPE => &XYZ,
                         &VALUE => "value" },        

B<Method 2 (permanent solution):> 
Find the attribute type like in Method 1. Insert the line 
              
              "xyz" => &XYZ,
          
into the hash Net::IPP::IPPAttribute::attributeTypes.
 
=item 2. You get the warning "Unknown Value type 0x88 for key "xyz". Performing no transformation.":

While de- or encoding a unknown IPP type was encountered. To permanently add 
this type to the API search for the name of this type in the RFCs and add this
type to the IPP type in IPP.pm. You also have to write transform methods for 
this IPP type. All value transformations between IPP byte encoding and Perl 
encoding are done in transformValue in IPPAttribute.pm. A additional testcase 
n t/transform.t would be nice, too.

Alternatively you can ignore this warning if you don't need the value of 
attribute xyz or if the value does not need to be transformed.

=item 3. You get the error "ERROR: IPP response is not RFC conform.":

The length check in testLengths() went wrong, the decoding became probably 
totally confused some bytes earlier. 

Bad Luck, the printer encoded the IPP response wrong (or you just found a bug 
in this API). This error simply says that a length field contained a greater 
length than the remaining bytes in the response. The API became probably 
totally confused much earlier than the offset states. 

If the printer is from HP you can try to run the same IPP request with the 
HP_BUGFIX option turned on. 

=item 4. You get the warning "WARNING: Collection Syntax not supported. Attribute xyz will have invalid value.":

Implement the collection syntax ;-)

=back

=head1 DEPENDENCIES

LWP: IPPRequest.pm uses LWP::UserAgent to send the HTTP Request.

=head1 EXPORT

None by default.

=head1 SEE ALSO

implements most of the IPP RFCs

=head1 AUTHOR

Author

Matthias Hilbig <bighil@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright

Copyright (c) 2004 Matthias Hilbig <bighil@cpan.org>
All rights reserved.
 
This program is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

=cut
