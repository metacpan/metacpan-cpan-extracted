###
# Copyright (c) 2004 Matthias Hilbig <bighil@cpan.org>
# All rights reserved.
# 
# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.
#

package Net::IPP::IPPUtil;

use strict;
use warnings;

use Net::IPP::IPP qw(:all);

require Exporter;
our @ISA = ("Exporter");
our @EXPORT_OK = qw(ippToString printIPP bytesToString printBytes searchGroup findAttribute findNextAttribute 
	findGroup findNextGroup isSuccessful printerStateToString jobStateToString operationToString groupToString 
	statusToString statusToDetailedString);
our %EXPORT_TAGS = ( 'all' => \@EXPORT_OK );

###
# convert group to string
#
# Parameter: $group - group to convert
#
# Return: $string with converted group
#
sub groupStructureToString($) {
	my $group = shift;
	my $string = "";
	$string .= "GROUP " . groupToString($group->{&TYPE}) . "\n";
	foreach my $key (sort keys %{$group}) {
		if ($key ne &TYPE) {
			my $value = $group->{$key};
			
			if (ref($value) eq 'HASH') {
				$value = $value->{&VALUE};		
			}
			
			if (ref($value) eq 'ARRAY') {
				$string .= "    " . $key . " = [";
				foreach my $val (@{$value}) {
					$string .= "$val, ";
				}
				$string .= "]\n";
			} else {
				$string .= "    " . $key . " = " . $value . "\n";
			}
		}
	}
	return $string;
}

###
# Convert perl structure to string
#
# Parameter: $ipp - IPP request to convert
# 
# Return: $string with converted perl structure
#
sub ippToString($) {
	my $ipp = shift;
	my $string = "";
	$string .= "URL: " . $ipp->{&URL} . "\n" if exists($ipp->{&URL});
	$string .= "REQUEST-ID: " . $ipp->{&REQUEST_ID} . "\n" if exists($ipp->{&REQUEST_ID});
	$string .= "STATUS: " . $ipp->{&STATUS} ." (" .statusToDetailedString($ipp->{&STATUS}) .  ")\n" if exists($ipp->{&STATUS});
	$string .= "OPERATION: " . operationToString($ipp->{&OPERATION}) . "\n" if exists($ipp->{&OPERATION});
	$string .= "VERSION: " . $ipp->{&VERSION} . "\n" if exists($ipp->{&VERSION});
	if (exists($ipp->{&GROUPS})) {
	  foreach my $group (@{$ipp->{&GROUPS}}) {
	    $string .= groupStructureToString($group);
	  }
	}
	return $string;
}

###
# print perl structure of IPP request/response
#
sub printIPP($) {
	my $ipp = shift;
	my $string = ippToString($ipp);
	print $string;
}

###
# helper function to dump hexview of bytes
#
sub bytesToString($) {
	use bytes;
	
	my $bytes = shift;
    my @bytes = unpack("c*", $bytes);

    my $width = 16; #how many bytes to print per line
    my $hexWidth = 3*$width;

	my $string = "";

    my $offset = 0;

    while ($offset *$width < length($bytes)) {
    	my $hexString = "";
    	my $charString = ""; 
    	for (my $i = 0; $i < $width; $i++) {
    		if ($offset*$width + $i < length($bytes)) {
    			my $char;
    			{use bytes;$char = substr($bytes, $offset*$width + $i, 1);}
			
    			$hexString .= sprintf("%02X ", ord($char));
    			if ($char =~ /[\w\-\:]/) {
    				$charString .= $char;
    			} else {
    				$charString .= ".";
    			}
    		}
    	}
	
    	$string .= sprintf("%-${hexWidth}s%s\n",$hexString,$charString);
    	$offset++;
    }
    return $string;
}

sub printBytes($) {
	my $bytes = shift;
	print bytesToString($bytes);
}

###
# Searches for attribute in group
#
# Parameter: $group - IPP group
#            $name  - name of IPP attribute
#
# Return: value of attribute if found, undef otherwise
#
sub searchGroup($$) {
	my $group = shift;
	my $name = shift;
	
	while (my ($key, $value) = each %{$group}) {
    	if ($key eq $name) {
		
    		# reset hash iterator
    		keys %{$group};
		
    		return $value;
    	}
	}
	
	return undef;
}


###
# Searches for next attribute in IPP structure
#
# Parameter: $ipp  - IPP structure
#            $name - name of IPP attribute
#
# Return: value of attribute if found, undef otherwise
#
# Each attribute must be unique in a group [RFC 2911 3.1.3], 
# so it is only necessary to remember the last group that was searched.
#
my $lastAttributeIndex = -1;
sub findNextAttribute($$) {
	my $ipp = shift;
	my $name = shift;

	my @groups = @{$ipp->{&GROUPS}};
	my $length = scalar(@groups);

	# search restarts automagically, because $lastAttributeIndex is 
	# initialized and resetted to -1
	for (my $i = $lastAttributeIndex + 1; $i < $length; $i++) {
		my $value = searchGroup($groups[$i], $name);
		if (defined($value)) {
			$lastAttributeIndex = $i;
			return $value;
		}	
	}

	$lastAttributeIndex = -1;
	return undef;	
}

###
# Search for first attribute in IPP structure
# Internally call findNextAttribute after resetting $lastIndex
#
# Parameter: $ipp - IPP structure
#           $name - name of IPP attribute
#
# Return: value of attribute if found, undef otherwise
#
sub findAttribute($$) {
	my $ipp = shift;
	my $name = shift;
	
	$lastAttributeIndex = -1;

	return findNextAttribute($ipp, $name);
}

###
# Search for next group in IPP structure
#
# Parameter: $ipp - IPP structure
#            $type - type of IPP group
#
# Return: group if a group with the specified type was found, undef otherwise
#
my $lastGroupIndex = -1;
sub findNextGroup($$) {
	my $ipp = shift;
	my $type = shift;
	my @groups = @{$ipp->{&GROUPS}};
	my $length = scalar(@groups);

	# search restarts automagically, because $lastGroupIndex is 
	# initialized and resetted to -1
	for (my $i = $lastGroupIndex + 1; $i < $length; $i++) {
		my $groupType = $groups[$i]->{&TYPE};
		if ($groupType == $type) {
			$lastGroupIndex = $i;
			return $groups[$i];
		}	
	}

	$lastGroupIndex = -1;
	return undef;	
}

###
# Search for first group in IPP structure
#
# Parameter: $ipp - IPP structure
#            $type - type of IPP group
#
# Return: group if a group with the specified type was found, undef otherwise
#
sub findGroup($$) {
	my $ipp = shift;
	my $type = shift;
	
	$lastGroupIndex = -1;

	return findNextGroup($ipp, $type);
}

###
# returns 1 if IPP request was successful, 0 otherwise
#
# Parameter: $response - IPP response
#
# Return: 1 if successful request, 0 otherwise
#
sub isSuccessful($) {
	my $response = shift;
	if (exists($response->{&STATUS})) {
		my $status = $response->{&STATUS};
		return ($status >= 0x0000 and $status <= 0x00ff);
	}
	return 0;
}

###
# look for key in the specified hash and return value if the key exists.
#
# Parameter: $key - key for hash
#        $hashref - reference to hash
#
# Return: value in hash if key exists, "unknown" otherwise
#
sub hashResolve($$) {
  my $key = shift;
  my $hashref = shift;

  if (exists($hashref -> {$key})) {
    return $hashref->{$key};
  } else {
    return "unknown";
  }
}

###
# The following functions are all build similar and could be made more complicated with AUTOLOADER :-)
# All functions use hashResolve to transform value to string. 
#
# Parameter: $value - value to transform to string
#
# Return: $value transformed to string
#

sub printerStateToString($) {
  my $state = shift;
  return hashResolve($state, \%Net::IPP::IPP::printerState);
}

sub jobStateToString($) {
  my $state = shift;
  return hashResolve($state, \%Net::IPP::IPP::jobState);
}

sub operationToString($) {
  my $operation = shift;
  return hashResolve($operation, \%Net::IPP::IPP::operation);
}

sub groupToString($) {
  my $group = shift;
  return hashResolve($group, \%Net::IPP::IPP::group);
}

sub statusToDetailedString($) {
  my $status = shift;
  return hashResolve($status, \%Net::IPP::IPP::statusCodes);
}

###
# returns type of IPP status.
#
# Parameter: $status - IPP status
#
# Return:
#   "informational" - Request received, continuing process
#      "successful" - The action was successfully received, understood, and accepted
#     "redirection" - Further action must be taken in order to complete the request
#    "client-error" - The request contains bad syntax or cannot be fulfilled
#    "server-error" - The IPP object  failed to fulfill an apparently valid request
#
sub statusToString($) {
	my $status = shift;
	if ($status >= 0x0000 and $status <= 0x00ff) {
		return "successful";
	} elsif ($status >= 0x0100 and $status <= 0x01ff) {
		return "informational";
	} elsif ($status >= 0x0200 and $status <= 0x02ff) {
		return "redirection";
	} elsif ($status >= 0x0400 and $status <= 0x04ff) {
		return "client-error";
	} elsif ($status >= 0x0500 and $status <= 0x05ff) {
		return "server-error";
	}
}


1;
__END__

=head1 NAME

Net::IPP::IPPUtil - API Helper functions

=cut
