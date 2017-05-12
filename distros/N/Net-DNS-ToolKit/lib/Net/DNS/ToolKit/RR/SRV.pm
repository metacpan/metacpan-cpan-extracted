package Net::DNS::ToolKit::RR::SRV;

use strict;
#use warnings;

use Net::DNS::ToolKit qw(
	get16
	put16
	dn_comp
	dn_expand
);
use Net::DNS::Codes qw(:constants);
use vars qw($VERSION);

$VERSION = do { my @r = (q$Revision: 0.03 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

=head1 NAME

Net::DNS::ToolKit::RR::SRV - Resource Record Handler

=head1 SYNOPSIS

  DO NOT use Net::DNS::ToolKit::RR::SRV
  DO NOT require Net::DNS::ToolKit::RR::SRV

  Net::DNS::ToolKit::RR::SRV is autoloaded by 
  class Net::DNS::ToolKit::RR and its methods
  are instantiated in a 'special' manner.

  use Net::DNS::ToolKit::RR;
  ($get,$put,$parse) = new Net::DNS::ToolKit::RR;

  ($newoff,$name,$type,$class,$ttl,$rdlength,
   $priority,$weight,$port,$target) =  $get->SRV(\$buffer,$offset);

  Note: the $get->SRV method is normally called
  via:  @stuff = $get->next(\$buffer,$offset);

  ($newoff,@dnptrs)=$put->SRV(\$buffer,$offset,\@dnptrs,
	$name,$type,$class,$ttl,$rdlength,
	$priority,$weight,$port,$target);

  ($NAME,$TYPE,$CLASS,$TTL,$rdlength,$priority,$weight,$port,$target)
    = $parse->SRV($name,$type,$class,$ttl,$rdlength,
	$priority,$weight,$port,$target);

=head1 DESCRIPTION

B<Net::DNS::ToolKit::RR:SRV> appends an SRV resource record to a DNS packet
under construction, recovers an SRV resource record from a packet being decoded, and
converts the numeric/binary portions of the resource record to human
readable form.

  Description from RFC2782.txt

  All RRs have the same top level format shown below:

                                    1  1  1  1  1  1
      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+  
    |              _SERVICE._PROTO.NAME             |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                      TYPE                     |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                     CLASS                     |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                      TTL                      |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                    RDLENGTH                   |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                    PRIORITY                   |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                     WEIGHT                    |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                      PORT                     |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                     TARGET                    |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+

    _Service._Proto.Name TTL Class SRV Priority Weight Port Target


  SERVICE The symbolic name of the desired service, as defined in 
        Assigned Numbers [STD 2] or locally.  An underscore (_) is 
        prepended to the service identifier to avoid collisions with
        DNS labels that occur in nature.
        Some widely used services, notably POP, don't have a single
        universal name.  If Assigned Numbers names the service
        indicated, that name is the only name which is legal for SRV
        lookups.  The Service is case insensitive.

  PROTO The symbolic name of the desired protocol, with an underscore
        (_) prepended to prevent collisions with DNS labels that occur
        in nature.  _TCP and _UDP are at present the most useful values
        for this field, though any name defined by Assigned Numbers or
        locally may be used (as for Service).  The Proto is case
        insensitive.

  NAME  The domain this RR refers to.  The SRV RR is unique in that the
        name one searches for is not this name; the example near the end
        shows this clearly.

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
	in octets of the followin RDATA field.

  PRIORITY The priority of this target host.  A client MUST attempt to
        contact the target host with the lowest-numbered priority it can
        reach; target hosts with the same priority SHOULD be tried in an
        order defined by the weight field.  The range is 0-65535.  This
        is a 16 bit unsigned integer in network byte order.

  WEIGHT A server selection mechanism.  The weight field specifies a
        relative weight for entries with the same priority. Larger
        weights SHOULD be given a proportionately higher probability of
        being selected. The range of this number is 0-65535.  This is a
        16 bit unsigned integer in network byte order.  Domain
        administrators SHOULD use Weight 0 when there isn't any server
        selection to do, to make the RR easier to read for humans (less
        noisy).  In the presence of records containing weights greater
        than 0, records with weight 0 should have a very small chance of
        being selected.

        In the absence of a protocol whose specification calls for the
        use of other weighting information, a client arranges the SRV
        RRs of the same Priority in the order in which target hosts,
        specified by the SRV RRs, will be contacted. The following
        algorithm SHOULD be used to order the SRV RRs of the same
        priority:

        To select a target to be contacted next, arrange all SRV RRs
        (that have not been ordered yet) in any order, except that all
        those with weight 0 are placed at the beginning of the list.

        Compute the sum of the weights of those RRs, and with each RR
        associate the running sum in the selected order. Then choose a
        uniform random number between 0 and the sum computed
        (inclusive), and select the RR whose running sum value is the
        first in the selected order which is greater than or equal to
        the random number selected. The target host specified in the
        selected SRV RR is the next one to be contacted by the client.
        Remove this SRV RR from the set of the unordered SRV RRs and
        apply the described algorithm to the unordered SRV RRs to select
        the next target host.  Continue the ordering process until there
        are no unordered SRV RRs.  This process is repeated for each
        Priority.

  PORT  The port on this target host of this service.  The range is 0-
        65535.  This is a 16 bit unsigned integer in network byte order.
        This is often as specified in Assigned Numbers but need not be.

  TARGET The domain name of the target host.  There MUST be one or more
        address records for this name, the name MUST NOT be an alias (in
        the sense of RFC 1034 or RFC 2181).  Implementors are urged, but
        not required, to return the address record(s) in the Additional
        Data section.  Unless and until permitted by future standards
        action, name compression is not to be used for this field.

        A Target of "." means that the service is decidedly not
        available at this domain.

=over 4

=item * @stuff = $get->SRV(\$buffer,$offset);

  Get the contents of the resource record.

  USE: @stuff = $get->next(\$buffer,$offset);

  where: @stuff = (
  $newoff $name,$type,$class,$ttl,$rdlength,
  	$priority,$weight,$port,$target);

All except the last four items, B<$priority,$weight,$port,$target>, are 
provided by the class loader, B<Net::DNS::ToolKit::RR>. The code in this 
method knows how to retrieve B<$priority,$weight,$port,$target>.

  input:        pointer to buffer,
                offset into buffer
  returns:      offset to next resource,
                @common RR elements,
		priority
		weight
		port
		target name

=cut

sub get {
  my($self,$bp,$offset) = @_;
  $offset += INT16SZ;	# don't need rdlength
  (my $priority,$offset) = get16($bp,$offset);
  (my $weight,$offset) = get16($bp,$offset);
  (my $port,$offset) = get16($bp,$offset);
  ($offset, my $target) = dn_expand($bp,$offset);
  return ($offset,$priority,$weight,$port,$target);
}

=item * ($newoff,@dnptrs)=$put->SRV(\$buffer,$offset,\@dnptrs,
	$name,$type,$class,$ttl,$subtype,$hostname);

Append an SRV record to $buffer.

  where @common = (
	$name,$type,$class,$ttl);

The method will insert the $rdlength, $subtype and $hostname, then
return the updated pointer to the array of compressed names            

The class loader, B<Net::DNS::ToolKit::RR>, inserts the @common elements and
returns updated @dnptrs. This module knows how to insert its RDATA and
calculate the $rdlength.

  input:        pointer to buffer,
                offset (normally end of buffer), 
                pointer to compressed name array,
                @common RR elements,
		priority
		weight
		port
		target name
  output:       offset to next RR,
                new pointer array,
           or   empty list () on error.

=cut

sub put {
  return () unless @_;	# always return on error
  my($self,$bp,$off,$dnp,$priority,$weight,$port,$target) = @_;
#print "$priority, $weight, $port, $target\n";
  my $rdlp = $off;	# save pointer to rdlength
  local *tgt = \$target;
  my $doff;		# rdata offset
  return () unless	# check for valid offset and get
	($doff = put16($bp,$off,0)) && # offset for rdlenth
	($off = put16($bp,$doff,$priority)) &&
	($off = put16($bp,$off,$weight)) &&
	($off = put16($bp,$off,$port)) &&
	(@_ = dn_comp($bp,$off,\$target));

  # new offset is first item in @_
  # rdlength = new offset - previous offset
  put16($bp,$rdlp, $_[0] - $doff);
  return(@_);
}

=item * (@COMMON,$priority,$weight,$port,$SRVDNAME) = $parse->SRV(@common,$priority,$weight,$target);

Converts binary/numeric field data into human readable form. The common RR
elements are supplied by the class loader, B<Net::DNS::ToolKit::RR>.
For SRV RR's, this returns $hostname terminated with '.'

  input:	priority
		weight
		port
		target name
  returns:	priority
		weight
		port
		SRV Domain Name.

=back

=cut

sub parse {
  my($self,$priority,$weight,$port,$target) = @_;
  return ($priority,$weight,$port,$target.'.');
}

=head1 DEPENDENCIES

	Net::DNS::ToolKit
	Net::DNS::Codes

=head1 EXPORT

	none

=head1 AUTHOR

Michael Robinton <michael@bizsystems.com>

=head1 COPYRIGHT

    Copyright 2003 - 2013, Michael Robinton <michael@bizsystems.com>
   
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
