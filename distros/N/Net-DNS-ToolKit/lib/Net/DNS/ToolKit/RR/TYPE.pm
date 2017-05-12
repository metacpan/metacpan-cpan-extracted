package Net::DNS::ToolKit::RR::TYPE;

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

$VERSION = do { my @r = (q$Revision: 0.01 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

=head1 NAME

Net::DNS::ToolKit::RR::TYPE - Unknown Resource Record Handler

=head1 SYNOPSIS

  DO NOT use Net::DNS::ToolKit::RR::TYPE
  DO NOT require Net::DNS::ToolKit::RR::TYPE

  Net::DNS::ToolKit::RR::TYPE is autoloaded by 
  class Net::DNS::ToolKit::RR and its methods
  are instantiated in a 'special' manner.

  use Net::DNS::ToolKit::RR;
  ($get,$put,$parse) = new Net::DNS::ToolKit::RR;

  ($newoff,$name,$type,$class,$ttl,$rdlength,
        $textdata) = $get->UnknownType(\$buffer,$offset);

  Note: the $get->UnknownType method is normally called
  via:  @stuff = $get->next(\$buffer,$offset);

  ($newoff,@dnptrs)=$put->UnknownType(\$buffer,$offset,\@dnptrs,
	$name,$type,$class,$ttl,$rdlength,$textdata);

  $NAME,$TYPE,$CLASS,$TTL,$rdlength,$textdata) 
    = $parse->UnknownType($name,$type,$class,$ttl,$rdlength,
        $textdata);

=head1 DESCRIPTION

B<Net::DNS::ToolKit::RR:TYPE> is loaded once for all unknown types and their
methods redirected to the TYPE module. i.e. for TYPE61, this code snippet is
autoloaded.

	package NET::DNS::ToolKit::RR::TYPE61
	*get   = \&Net::DNS::ToolKit::RR::TYPE::get;
	*put   = \&Net::DNS::ToolKit::RR::TYPEnn::put;
	*parse = \&Net::DNS::ToolKit::RR::TYPEnn::parse;

  Description from RFC3597

  5. Text Representation

   In the "type" field of a master file line, an unknown RR type is
   represented by the word "TYPE" immediately followed by the decimal RR
   type number, with no intervening whitespace.  In the "class" field,
   an unknown class is similarly represented as the word "CLASS"
   immediately followed by the decimal class number.

   This convention allows types and classes to be distinguished from
   each other and from TTL values, allowing the "[<TTL>] [<class>]
   <type> <RDATA>" and "[<class>] [<TTL>] <type> <RDATA>" forms of
   [RFC1035] to both be unambiguously parsed.

   The RDATA section of an RR of unknown type is represented as a
   sequence of white space separated words as follows:

      The special token \# (a backslash immediately followed by a hash
      sign), which identifies the RDATA as having the generic encoding
      defined herein rather than a traditional type-specific encoding.

      An unsigned decimal integer specifying the RDATA length in octets.

      Zero or more words of hexadecimal data encoding the actual RDATA
      field, each containing an even number of hexadecimal digits.

   If the RDATA is of zero length, the text representation contains only
   the \# token and the single zero representing the length.

	i.e.
	CLASS32     TYPE731         \# 6 abcd012345

=over 4

=item * @stuff = $get->UnknownType(\$buffer,$offset);

  Get the contents of the resource record.

  USE: @stuff = $get->next(\$buffer,$offset);

  where: @stuff = (
  $newoff $name,$type,$class,$ttl,$rdlength,
  $TYPEdata );

All except the last item, B<$textdata>, is provided by
the class loader, B<Net::DNS::ToolKit::RR>. The code in this method knows
how to retrieve B<$TYPEdata>.

  input:        pointer to buffer,
                offset into buffer
  returns:      offset to next resource,
                @common RR elements,
		TYPEdata

=cut

sub get {
  my($self,$bp,$offset) = @_;
  (my $rdend,$offset) = get16($bp,$offset);	# get rdlength
  (my $string,$offset) = getstring($bp,$offset,$rdend);
  return($offset,$string);
}

=item * ($newoff,@dnptrs)=$put->UnknownType(\$buffer,$offset,\@dnptrs,
	$name,$type,$class,$ttl,$rdlength,$TYPEdata);

Append an unknown record to $buffer.

  where @common = (
	$name,$type,$class,$ttl);

The method will insert the $rdlength and $TYPEdata, then
pass through the updated pointer to the array of compressed names            

The class loader, B<Net::DNS::ToolKit::RR>, inserts the @common elements and
returns updated @dnptrs. This module knows how to insert its RDATA and
calculate the $rdlength.

  input:        pointer to buffer,
                offset (normally end of buffer), 
                pointer to compressed name array,
                @common RR elements,
		TYPEdata
  output:       offset to next RR,
                new compressed name pointer array,
           or   empty list () on error.

=cut

sub put {
  return () unless @_;		# always return on error
  my($self,$bp,$off,$dnp,$TYPEdata) = @_;
  my $rdlp = $off;		# save pointer to rdlength
  my $doff;
  return () unless		# check for valid offset and get
	($off = $doff = put16($bp,$off,0));	# offset to text string
  my $len = length($TYPEdata);
  $off = putstring($bp,$off,\$TYPEdata);
  # rdlength = new offset - previous offset
  put16($bp,$rdlp, $off - $doff);
  return($off,@$dnp);
}

=item * (@COMMON,$TYPEdata) = $parse->UnknownType(@common,$TYPEdata);

Converts binary/numeric field data into human readable form. The common RR
elements are supplied by the class loader, B<Net::DNS::ToolKit::RR>.
For UnknownType RR's, this returns the hex string described in RFC3597

  input:	unknown binary
  returns:	hex string

=back

=cut

sub parse {
  shift;	# $self
  my $len = length($_[0]);
  my $pat = 'H'. $len * 2;
  return '\# '. $len .' '. unpack($pat,$_[0]);
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
