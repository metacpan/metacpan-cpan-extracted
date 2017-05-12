package Net::DNS::ToolKit::RR::SOA;

use strict;
#use warnings;

use Net::DNS::ToolKit qw(
	get16
	get32
	put16
	put32
	dn_comp
	dn_expand
);
use Net::DNS::Codes qw(:constants);
use vars qw($VERSION);

$VERSION = do { my @r = (q$Revision: 0.02 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

=head1 NAME

Net::DNS::ToolKit::RR::SOA - Resource Record Handler

=head1 SYNOPSIS

  DO NOT use Net::DNS::ToolKit::RR::SOA
  DO NOT require Net::DNS::ToolKit::RR::SOA

  Net::DNS::ToolKit::RR::SOA is autoloaded by 
  class Net::DNS::ToolKit::RR and its methods
  are instantiated in a 'special' manner.

  use Net::DNS::ToolKit::RR;
  ($get,$put,$parse) = new Net::DNS::ToolKit::RR;

  ($newoff,$name,$type,$class,$ttl,$rdlength,
        ) = $get->SOA(\$buffer,$offset);

  Note: the $get->SOA method is normally called
  via:  @stuff = $get->next(\$buffer,$offset);

  ($newoff,@dnptrs)=$put->SOA(\$buffer,$offset,\@dnptrs,
     $name,$type,$class,$ttl,
     $mname,$rname,$serial,$refresh,$retry,$expire,$min);

  $NAME,$TYPE,$CLASS,$TTL,$rdlength,
  $MNAME,$RNAME,$serial,$refresh,$retry,$expire,$min) 
    = $parse->SOA($name,$type,$class,$ttl,$rdlength,
      $mname,$rname,$serial,$refresh,$retry,$expire,$min);

=head1 DESCRIPTION

B<Net::DNS::ToolKit::RR:SOA> appends an SOA resource record to a DNS packet
under construction, recovers an SOA resource record from a packet being decoded, and
converts the numeric/binary portions of the resource record to human
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

    3.3.13. SOA RDATA format

    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    /                     MNAME                     /
    /                                               /
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    /                     RNAME                     /
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                    SERIAL                     |
    |                                               |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                    REFRESH                    |
    |                                               |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                     RETRY                     |
    |                                               |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                    EXPIRE                     |
    |                                               |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                    MINIMUM                    |
    |                                               |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+

    where:

    MNAME The <domain-name> of the name server that was
	the original or primary source of data for this 
	zone.

    RNAME A <domain-name> which specifies the mailbox of
	the person responsible for this zone.

    SERIAL The unsigned 32 bit version number of the 
	original copy of the zone.  Zone transfers 
	preserve this value.  This value wraps and 
	should be compared using sequence space 
	arithmetic.

    REFRESH A 32 bit time interval before the zone 
	should be refreshed.

    RETRY A 32 bit time interval that should elapse 
	before a failed refresh should be retried.

    EXPIRE A 32 bit time value that specifies the upper 
	limit on the time interval that can elapse 
	before the zone is no longer authoritative.

    MINIMUM The unsigned 32 bit minimum TTL field that
	should be exported with any RR from this zone.

SOA records cause no additional section processing.

All times are in units of seconds.

Most of these fields are pertinent only for name server maintenance
operations.  However, MINIMUM is used in all query operations that
retrieve RRs from a zone.  Whenever a RR is sent in a response to a
query, the TTL field is set to the maximum of the TTL field from the RR
and the MINIMUM field in the appropriate SOA.  Thus MINIMUM is a lower
bound on the TTL field for all RRs in a zone.  Note that this use of
MINIMUM should occur when the RRs are copied into the response and not
when the zone is loaded from a master file or via a zone transfer.  The
reason for this provison is to allow future dynamic update facilities to
change the SOA RR with known semantics.

=over 4

=item * @stuff = $get->SOA(\$buffer,$offset);

  Get the contents of the resource record.

  USE: @stuff = $get->next(\$buffer,$offset);

  where: @stuff = (
  $newoff $name,$type,$class,$ttl,$rdlength,
  $mname,$rname,$serial,$refresh,$retry,$expire,$min);

All except the last five (5) items,
B<$mname,$rname,$serial,$refresh,$retry,$expire,$min>, are provided by
the class loader, B<Net::DNS::ToolKit::RR>. The code in this method knows
how to retrieve B<$mname,$rname,$serial,$refresh,$retry,$expire,$min>.

  input:	pointer to buffer,
		offset into buffer
  returns:	offset to next resource,
		@common RR elements,
		primary server name,
		zone contact,
		RR serial number,
		REFRESH timer,
		RETRY timer,
		EXPIRE timer,
		MINIMUM ttl

=cut

sub get {
  my($self,$bp,$offset) = @_;
  $offset += INT16SZ;	# don't need rdlength
  ($offset, my $mname) = dn_expand($bp,$offset);
  ($offset, my $rname) = dn_expand($bp,$offset);
  (my $serial,$offset) = get32($bp,$offset);
  (my $refresh,$offset) = get32($bp,$offset);
  (my $retry,$offset) = get32($bp,$offset);
  (my $expire,$offset) = get32($bp,$offset);
  (my $min,$offset) = get32($bp,$offset);
  return($offset,$mname,$rname,$serial,$refresh,$retry,$expire,$min);
}

=item * ($newoff,@dnptrs)=$put->SOA(\$buffer,$offset,\@dnptrs,
	$name,$type,$class,$ttl,
	$mname,$rname,$serial,$refresh,$retry,$expire,$min);

Append an SOA record to $buffer.

  where @common = (
	$name,$type,$class,$ttl);

The method will insert the $rdlength,
$mname, $rname, $serial, $refresh, $retry, $expire, and $min, then
return the updated pointer to the array of compressed names            

The class loader, B<Net::DNS::ToolKit::RR>, inserts the @common elements and
returns updated @dnptrs. This module knows how to insert its RDATA and
calculate the $rdlength.

  input:	pointer to buffer,
		offset (normally end of buffer), 
		pointer to compressed name array,
		@common RR elements,
		primary server name,
		zone contact,
		RR serial number,
		REFRESH timer,
		RETRY timer,
		EXPIRE timer,
		MINIMUM ttl
		
  output:       offset to next RR,
		new compressed name pointer array,
	   or	empty list () on error.

=cut

sub put {
  return () unless @_;	# always return on error
  my($self,$bp,$off,$dnp,$mname,$rname,$serial,$refresh,$retry,$expire,$min) = @_;
  my $rdlp = $off;	# save pointer to rdlength
  my ($doff,@dnptrs);	# data start, pointer array
  return () unless	# check for valid and get
	($doff = put16($bp,$off,0)) && # offset for names
	(($off,@dnptrs) = dn_comp($bp,$doff,\$mname,$dnp)) &&
	(($off,@dnptrs) = dn_comp($bp,$off,\$rname,\@dnptrs)) &&
	($off = put32($bp,$off,$serial)) &&
	($off = put32($bp,$off,$refresh)) &&
	($off = put32($bp,$off,$retry)) &&
	($off = put32($bp,$off,$expire)) &&
	($off = put32($bp,$off,$min));
  # rdlength = new offset - previous offset
  put16($bp,$rdlp, $off - $doff);
  return($off,@dnptrs);
}

=item * (@COMMON,$MNAME,$RNAME,$serial,$refresh,$retry,$expire,$min)
	= $parse->A(@common,
	$mname,$rname,$serial,$refresh,$retry,$expire,$min);

Converts binary/numeric field data into human readable form. The common RR
elements are supplied by the class loader, B<Net::DNS::ToolKit::RR>.
For SOA RR's, this returns $mxdname terminated with '.'

  input:	primary server name,
		zone contact,
		serial number,
		refresh timer,
		retry timer,
		expire timer,
		minimum ttl
  returns:	SERVER NAME '.' terminated
		CONTACT NAME '.' terminated
		serial number,
		refresh timer,
		retry timer,
		expire timer,
		minimum ttl

=back

=cut

sub parse {
  my($self,$mname,$rname,@rest) = @_;
  return($mname.'.',$rname.'.',@rest);
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
