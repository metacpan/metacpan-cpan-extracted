package Net::DNS::ToolKit::RR::AAAA;

use strict;
#use warnings;

# This file contains the working code for
# the RR_AAAA record methods.

use Net::DNS::ToolKit qw(
	put16
	getIPv6
	putIPv6
	ipv6_aton
	ipv6_n2x
);
use Net::DNS::Codes qw(:constants);
use vars qw($VERSION);

$VERSION = do { my @r = (q$Revision: 0.01 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

=head1 NAME

Net::DNS::ToolKit::RR::AAAA - Resource Record Handler

=head1 SYNOPSIS

  DO NOT use Net::DNS::ToolKit::RR::AAAA
  DO NOT require Net::DNS::ToolKit::RR::AAAA

  Net::DNS::ToolKit::RR::AAAA is autoloaded by 
  class Net::DNS::ToolKit::RR and its methods
  are instantiated in a 'special' manner.

  use Net::DNS::ToolKit::RR;
  ($get,$put,$parse) = new Net::DNS::ToolKit::RR;

  ($newoff,$name,$type,$class,$ttl,$rdlength,
        $netaddr) = $get->AAAA(\$buffer,$offset);

  Note: the $get->AAAA method is normally called
  via:  @stuff = $get->next(\$buffer,$offset);

  ($newoff,@dnptrs)=$put->AAAA(\$buffer,$offset,\@dnptrs,
        $name,$type,$class,$ttl,$ipv6addr);

  $name,$TYPE,$CLASS,$TTL,$rdlength,$IP6addr) 
    = $parse->AAAA($name,$type,$class,$ttl,$rdlength,
        $ipv6addr);

=head1 DESCRIPTION

B<Net::DNS::ToolKit::RR:AAAA> appends an AAAA resource record to a DNS packet
under construction, recovers an AAAA resource record from a packet being decoded, 
and converts the numeric/binary portions of the resource record to human
readable form.

  Description from RFC1035.txt

  3.2.1. Format

  All RRs have the same top level format shown below:

                                    1  1  1  1  1  1
      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                      NAME                     |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                      TYPE                     |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                     CLASS                     |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                      TTL                      |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                   RDLENGTH                    |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--|
    |                     RDATA                     |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+

  NAME  an owner name, i.e., the name of the node to which this
        resource record pertains.

  TYPE  two octets containing one of the RR TYPE codes.

  CLASS two octets containing one of the RR CLASS codes.

  TTL   a 32 bit signed integer that specifies the time interval
        that the resource record may be cached before the source
        of the information should again be consulted.  Zero
        values are interpreted to mean that the RR can only be
        used for the transaction in progress, and should not be
        cached.  For example, SOA records are always distributed
        with a zero TTL to prohibit caching.  Zero values can
        also be used for extremely volatile data.

  RDLENGTH an unsigned 16 bit integer that specifies the length
        in octets of the RDATA field.

  RDATA a variable length string of octets that describes the
        resource.  The format of this information varies
        according to the TYPE and CLASS of the resource record.

  Description from RFC1884.txt

                  AAAA RDATA format
                                    1  1  1  1  1  1
      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                                               |
    +                                               +
    |                  128 bit                      |
    +                IPv6 ADDRESS                   +
    |                                               |
    +                                               +
    |                                               |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+

=over 4

=item * @stuff = $get->AAAA(\$buffer,$offset);

  Get the contents of the resource record.

  USE: @stuff = $get->next(\$buffer,$offset);

  where: @stuff = (
  $newoff $name,$type,$class,$ttl,$rdlength,
  $ipv6addr );

All except the last item, B<$ipv6addr>, is provided by
the class loader, B<Net::DNS::ToolKit::RR>. The code in this method knows
how to retrieve B<$ipv6addr>.

  input:        pointer to buffer,
                offset into buffer
  returns:      offset to next resource,
                @common RR elements,
                128 bit IPv6 address 

  NOTE: convert IPv6 address to hex or hex + dotquad
        using Net::DNS::ToolKit::ipv6_n2x or ipv6_ntd
	respectively.

=cut

sub get {
  my($self,$bp,$offset) = @_;
  $offset += INT16SZ;	# don't need rdlength
  my($ipv6addr,$newoff) = getIPv6($bp,$offset);
  return ($newoff,$ipv6addr);
}

=item * ($newoff,@dnptrs)=$put->AAAA(\$buffer,$offset,\@dnptrs,  
        @common,$ipv6addr);

Append an AAAA record to $buffer.

  where @common = (
	$name,$type,$class,$ttl);

The method will insert the $rdlength and $ipv6addr, then
pass through the updated pointer to the array of compressed names            

The class loader, B<Net::DNS::ToolKit::RR>, inserts the @common elements and
returns updated @dnptrs. This module knows how to insert its RDATA and
calculate the $rdlength.

  input:        pointer to buffer,
                offset (normally end of buffer), 
                pointer to compressed name array,
                @common RR elements,
                128 bit IPv6 address
  output:       offset to next RR,
                new compressed name pointer array,
           or   empty list () on error.

=cut

sub put {
  return () unless @_;	# always return on error
  my($self,$bp,$off,$dnp,$ipv6addr) = @_;
  return () unless  
	($off = put16($bp,$off,NS_IN6ADDRSZ));
    return(putIPv6($bp,$off,$ipv6addr), @$dnp);
  }

=item * (@COMMON,$IPaddr) = $parse->AAAA(@common,$ipv6addr);

Converts binary/numeric field data into human readable form. The common RR
elements are supplied by the class loader, B<Net::DNS::ToolKit::RR>. This 
module knows how to parse its RDATA.

        EXAMPLE
Common is: name,$type,$class,$ttl,$rdlength

  name       '.' is appended
  type       numeric to text 
  class      numeric to text 
  ttl        numeric to text
  rdlength   is a number
  rdata      RR specific conversion

Resource Record B<AAAA> returns $rdata containing a 128 bit IPv6
address. The parse operation would be:

input:

  name       foo.bar.com
  type       1  
  class      1  
  ttl        123
  rdlength   4  
  rdata      a 128 bit IPv6 address

output:

  name       foo.bar.com
  type       T_AAAA
  class      C_IN
  ttl        2m 3s
  rdlength   16
  rdata      FE:0:0:0:1:2:3:4

=back

=cut

sub parse {
  shift;	# $self
  ipv6_n2x(shift);
}

=head1 DEPENDENCIES

        Net::DNS::ToolKit
        Net::DNS::Codes

=head1 EXPORT

	none

=head1 AUTHOR

Michael Robinton <michael@bizsystems.com>

=head1 COPYRIGHT

    Copyright 2003 - 2011, Michael Robinton <michael@bizsystems.com>
   
Michael Robinton <michael@bizsystems.com>

All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of either:

  a) the GNU General Public License as published by the Free
  Software Foundation; either version 2, or (at your option) any
  later version, or

  b) the "Artistic License" which comes with this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of 
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either    
the GNU General Public License or the Artistic License for more details.

You should have received a copy of the Artistic License with this
distribution, in the file named "Artistic".  If not, I'll be glad to provide
one.

You should also have received a copy of the GNU General Public License
along with this program in the file named "Copying". If not, write to the

        Free Software Foundation, Inc.                        
        59 Temple Place, Suite 330
        Boston, MA  02111-1307, USA                                     

or visit their web page on the internet at:                      

        http://www.gnu.org/copyleft/gpl.html.

=head1 See also:

Net::DNS::Codes(3), Net::DNS::ToolKit(3)

=cut

1;
