package Net::DNS::ToolKit::RR::MINFO;

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

$VERSION = do { my @r = (q$Revision: 0.01 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

=head1 NAME

Net::DNS::ToolKit::RR::MINFO - Resource Record Handler

=head1 SYNOPSIS

  DO NOT use Net::DNS::ToolKit::RR::MINFO
  DO NOT require Net::DNS::ToolKit::RR::MINFO

  Net::DNS::ToolKit::RR::MINFO is autoloaded by 
  class Net::DNS::ToolKit::RR and its methods
  are instantiated in a 'special' manner.

  use Net::DNS::ToolKit::RR;
  ($get,$put,$parse) = new Net::DNS::ToolKit::RR;

  ($newoff,$name,$type,$class,$ttl,$rdlength,
        ) = $get->MINFO(\$buffer,$offset);

  Note: the $get->MINFO method is normally called
  via:  @stuff = $get->next(\$buffer,$offset);

  ($newoff,@dnptrs)=$put->MINFO(\$buffer,$offset,\@dnptrs,
     $name,$type,$class,$ttl,
     $mname,$errname);

  $NAME,$TYPE,$CLASS,$TTL,$rdlength,
  $MNAME,$RNAME,$serial,$refresh,$retry,$expire,$min) 
    = $parse->MINFO($name,$type,$class,$ttl,$rdlength,
      $mname,$errname);

=head1 DESCRIPTION

B<Net::DNS::ToolKit::RR:MINFO> appends an MINFO resource record to a DNS packet
under construction, recovers an MINFO resource record from a packet being decoded, and
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
	cached.  For example, MINFO records are always distributed
	with a zero TTL to prohibit caching.  Zero values can
	also be used for extremely volatile data.

  RDLENGTH an unsigned 16 bit integer that specifies the length
	in octets of the RDATA field.

  RDATA a variable length string of octets that describes the
	resource.  The format of this information varies
	according to the TYPE and CLASS of the resource record.

    3.3.13. MINFO RDATA format

    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    /                    RMAILBX                    /
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    /                    EMAILBX                    /
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+

  where:

  RMAILBX A <domain-name> which specifies a mailbox which is
          responsible for the mailing list or mailbox.  If this
          domain name names the root, the owner of the MINFO RR is
          responsible for itself.  Note that many existing mailing
          lists use a mailbox X-request for the RMAILBX field of
          mailing list X, e.g., Msgroup-request for Msgroup.  This
          field provides a more general mechanism.

  EMAILBX A <domain-name> which specifies a mailbox which is to
          receive error messages related to the mailing list or
          mailbox specified by the owner of the MINFO RR (similar
          to the ERRORS-TO: field which has been proposed).  If
          this domain name names the root, errors should be
          returned to the sender of the message.

MINFO records cause no additional section processing.

=over 4

=item * @stuff = $get->MINFO(\$buffer,$offset);

  Get the contents of the resource record.

  USE: @stuff = $get->next(\$buffer,$offset);

  where: @stuff = (
  $newoff $name,$type,$class,$ttl,$rdlength,
  $rname,$errname);

All except the last five (2) items,
B<$mname,$errname>, are provided by
the class loader, B<Net::DNS::ToolKit::RR>. The code in this method knows
how to retrieve B<$mname,$errname>.

  input:	pointer to buffer,
		offset into buffer
  returns:	offset to next resource,
		@common RR elements,
		responsible.mail.box
		error.mail.box

=cut

sub get {
  my($self,$bp,$offset) = @_;
  $offset += INT16SZ;	# don't need rdlength
  ($offset, my $mname) = dn_expand($bp,$offset);
  ($offset, my $errname) = dn_expand($bp,$offset);
  return($offset,$mname,$errname);
}

=item * ($newoff,@dnptrs)=$put->MINFO(\$buffer,$offset,\@dnptrs,
	$name,$type,$class,$ttl,
	$mname,$errname);

Append an MINFO record to $buffer.

  where @common = (
	$name,$type,$class,$ttl);

The method will insert the $rdlength,
$mname, $errname then
return the updated pointer to the array of compressed names            

The class loader, B<Net::DNS::ToolKit::RR>, inserts the @common elements and
returns updated @dnptrs. This module knows how to insert its RDATA and
calculate the $rdlength.

  input:	pointer to buffer,
		offset (normally end of buffer), 
		pointer to compressed name array,
		@common RR elements,
		responsible.mail.box
		error.mail.box
		
  output:       offset to next RR,
		new compressed name pointer array,
	   or	empty list () on error.

=cut

sub put {
  return () unless @_;	# always return on error
  my($self,$bp,$off,$dnp,$mname,$errname) = @_;
  my $rdlp = $off;	# save pointer to rdlength
  my ($doff,@dnptrs);	# data start, pointer array
  return () unless	# check for valid and get
	($doff = put16($bp,$off,0)) && # offset for names
	(($off,@dnptrs) = dn_comp($bp,$doff,\$mname,$dnp)) &&
	(($off,@dnptrs) = dn_comp($bp,$off,\$errname,\@dnptrs));

  # rdlength = new offset - previous offset
  put16($bp,$rdlp, $off - $doff);
  return($off,@dnptrs);
}

=item * (@COMMON,$MNAME,$ERRNAME)
	= $parse->A(@common,
	$mname,$errname);

Converts binary/numeric field data into human readable form. The common RR
elements are supplied by the class loader, B<Net::DNS::ToolKit::RR>.
For MINFO RR's, this returns $mxdname terminated with '.'

  input:	responsible.mail.box
		error.mail.box
  returns:	responsible.mail.box '.' terminated
		error.mail.box '.' terminated

=back

=cut

sub parse {
  my($self,$mname,$errname) = @_;
  return($mname.'.',$errname.'.');
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
