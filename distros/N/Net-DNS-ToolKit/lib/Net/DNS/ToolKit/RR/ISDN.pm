package Net::DNS::ToolKit::RR::ISDN;

use strict;
#use warnings;
#use diagnostics;

use Net::DNS::ToolKit qw(
	get16
	put16
	get1char
	put1char
	dn_comp
	dn_expand
	putstring
	getstring
);
use Net::DNS::Codes qw(:constants);
use vars qw($VERSION);

$VERSION = do { my @r = (q$Revision: 0.02 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

=head1 NAME

Net::DNS::ToolKit::RR::ISDN - Resource Record Handler

=head1 SYNOPSIS

  DO NOT use Net::DNS::ToolKit::RR::ISDN
  DO NOT require Net::DNS::ToolKit::RR::ISDN

  Net::DNS::ToolKit::RR::ISDN is autoloaded by 
  class Net::DNS::ToolKit::RR and its methods
  are instantiated in a 'special' manner.

  use Net::DNS::ToolKit::RR;
  ($get,$put,$parse) = new Net::DNS::ToolKit::RR;

  ($newoff,$name,$type,$class,$ttl,$rdlength,
        $textdata) = $get->ISDN(\$buffer,$offset);

  Note: the $get->ISDN method is normally called
  via:  @stuff = $get->next(\$buffer,$offset);

  ($newoff,@dnptrs)=$put->ISDN(\$buffer,$offset,\@dnptrs,
	$name,$type,$class,$ttl,$rdlength,$textdata);

  $NAME,$TYPE,$CLASS,$TTL,$rdlength,$textdata) 
    = $parse->ISDN($name,$type,$class,$ttl,$rdlength,
        $textdata);

=head1 DESCRIPTION

B<Net::DNS::ToolKit::RR:ISDN> appends an ISDN resource record to a DNS packet under
construction, recovers an ISDN resource record from a packet being decoded, and 
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

  NAME	an owner name, i.e., the name of the node to which this
	resource record pertains.

  TYPE	two octets containing one of the RR TYPE codes.

  CLASS	two octets containing one of the RR CLASS codes.

  TTL	a 32 bit signed integer that specifies the time interval
	that the resource record may be cached before the source
	of the information should again be consulted.  Zero
	values are interpreted to mean that the RR can only be
	used for the transaction in progress, and should not be
	cached.  For example, SOA records are always distributed
	with a zero TTL to prohibit caching.  Zero values can
	also be used for extremely volatile data.

  RDLENGTH an unsigned 16 bit integer that specifies the length
	in octets of the RDATA field.

  RDATA	a variable length string of octets that describes the
	resource.  The format of this information varies
	according to the TYPE and CLASS of the resource record.

  RFC 1183 ISDN RDATA format

    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    /                 ISDN-ADDRESS                  /
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    /                  SUBADDRESS                   /
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+

    where:

    ISDN-ADDRESS  A character-string wich identifies the ISDN number.
    SUBADDRESS    An optional character-string specifying the subaddress

=over 4

=item * @stuff = $get->ISDN(\$buffer,$offset);

  Get the contents of the resource record.

  USE: @stuff = $get->next(\$buffer,$offset);

  where: @stuff = (
  $newoff $name,$type,$class,$ttl,$rdlength,
  $textdata );

All except the last item, B<$textdata>, is provided by
the class loader, B<Net::DNS::ToolKit::RR>. The code in this method knows
how to retrieve B<$textdata>.

  input:        pointer to buffer,
                offset into buffer
  returns:      offset to next resource,
                @common RR elements,
		text string(s)

=cut

sub get {
  my($self,$bp,$offset) = @_;
  (my $rdend,$offset) = get16($bp,$offset);	# get rdlength
  $rdend += $offset;	# end pointer
  my @tdata;
  while($offset < $rdend) {
    my $len = get1char($bp,$offset);
    (my $string,$offset) = getstring($bp,$offset+1,$len);
    push @tdata, $string;
  }
  return($offset,@tdata);
}

=item * ($newoff,@dnptrs)=$put->ISDN(\$buffer,$offset,\@dnptrs,
	$name,$type,$class,$ttl,$rdlength,$textdata);

Append a ISDN record to $buffer.

  where @common = (
	$name,$type,$class,$ttl);

The method will insert the $rdlength and $textdata, then
pass through the updated pointer to the array of compressed names            

The class loader, B<Net::DNS::ToolKit::RR>, inserts the @common elements and
returns updated @dnptrs. This module knows how to insert its RDATA and
calculate the $rdlength.

  input:        pointer to buffer,
                offset (normally end of buffer), 
                pointer to compressed name array,
                @common RR elements,
		text string(s).
  output:       offset to next RR,
                new compressed name pointer array,
           or   empty list () on error.

  Note:	Double quotes embedded in the text
	should be escaped. i.e. \"

=cut

sub put {
  return () unless @_;		# always return on error
  my($self,$bp,$off,$dnp,@textdata) = @_;
  my $rdlp = $off;		# save pointer to rdlength
  my $doff;
  return () unless		# check for valid offset and get
	($off = $doff = put16($bp,$off,0));	# offset to text string
  foreach(0..$#textdata) {
    $textdata[$_] =~ s/\\"/"/g;	# unescape embedded quotes
    my $len = length($textdata[$_]);
    return () if $len > 255;
    $off = put1char($bp,$off,$len);
    $off = putstring($bp,$off,\$textdata[$_]);
  }
  # rdlength = new offset - previous offset
  put16($bp,$rdlp, $off - $doff);
  return($off,@$dnp);
}

=item * (@COMMON,$textdata) = $parse->ISDN(@common,$textdata);

Converts binary/numeric field data into human readable form. The common RR
elements are supplied by the class loader, B<Net::DNS::ToolKit::RR>.
For ISDN RR's, this returns the text strings, each surrounded by double quotes.

  input:	text string(s)
  returns:	"text string(s)"

=back

=cut

sub parse {
  shift;	# $self
  my @ret;
  foreach(@_) {
    $_ =~ s/"/\\"/g;	# escape embedded quotes
    push @ret, '"'.$_.'"';
  }
  return wantarray ? @ret : $ret[0];
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
