package Net::DNS::ToolKit::RR::Template;

use strict;
#use warnings;

# This file contains the working code for
# the RR_A record methods.
# They are not really in the A.pm file, they
# are imported into that namespace from here
# so that this example can show a functional
# module containing real code.

# The functions needed for 'A' records
# are 'put16', 'getIPv4', putIPv4, inet_aton,
# and inet_ntoa.  Other RR types will need 
# different and/or additional functions.

use Net::DNS::ToolKit qw(
	put16
	getIPv4
	putIPv4
	inet_aton
	inet_ntoa
);
use Net::DNS::Codes qw(:constants);
use vars qw($VERSION);

$VERSION = do { my @r = (q$Revision: 0.02 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

=head1 NAME

Net::DNS::ToolKit::RR::Template - template for resource records

=head1 SYNOPSIS

This file is a template from which to create new resource record
manipulation methods. While these modules may be loaded directly for
testing, they are intended to be loaded by the class loader
B<Net::DNS::ToolKit::RR>. The SYNOPSIS section of specific RR documentation
should begin with the caveat:

I<edit this text to conform to your RR method>

  DO NOT use Net::DNS::ToolKit::RR::XYZ
  DO NOT require Net::DNS::ToolKit::RR::XYZ

  Net::DNS::ToolKit::RR::XYZ is autoloaded by 
  class Net::DNS::ToolKit::RR and its methods
  are instantiated in a 'special' manner.

  use Net::DNS::ToolKit::RR;
  ($get,$put,$parse) = new Net::DNS::ToolKit::RR;

  ($newoff,$name,$type,$class,$ttl,$rdlength,
        $rdata,...) = $get->XYZ(\$buffer,$offset);

  Note: the $get->XYZ method is normally called
  via:  @stuff = $get->next(\$buffer,$offset);

  ($newoff,@dnptrs)=$put->XYZ(\$buffer,$offset,\@dnptrs,
	$name,$type,$class,$ttl,$rdata,...);

  $NAME,$TYPE,$CLASS,$TTL,$rdlength,$RDATA) 
    = $parse->XYZ($name,$type,$class,$ttl,$rdlength,
        $rdata,...);

=head1 DESCRIPTION

B<Net::DNS::ToolKit::RR:XYZ> appends an XYZ resource record to a DNS packet under
construction, recovers an XYZ resource record from a packet being decoded, and 
converts the numeric/binary portions of the resource record to human
readable form.

Description from RFC1035.txt or other specification document.

I<edit this text to conform to your RR method>

See: I<Net::DNS::ToolKit::RR::A> and I<Net::DNS::ToolKit::RR::SOA> for
examples.

Each RR module contains three methods which provide the RR specific
content manipulation. The data common to all resource modules is handled
from within the class loader prior to handing the request over the the
specific resource record method. Because of this, the DESCRIPTION of the
method action is somewhat misleading. As an example, lets dissect the 'parse' method:

  $NAME,$TYPE,$CLASS,$TTL,$rdlength,$RDATA,...) 
    = $parse->XYZ($name,$type,$class,$ttl,$rdlength,
        $rdata,...);

The common elements for all resource records are:

  $name,$type,$class,$ttl,$rdlength

These are handled by the class loader and the local method actually only
receives a request to provide the '$rdata' portion. While the description of
the method as called from the user program is as above, the implementation
looks like this for and 'A' resource record. The $rdata is handled as
follows:

  $IPaddr = $classloader->A($netaddr);

  sub parse {
    shift;	# $self
    inet_ntoa($netaddr);
  }

As you can see, all that is passed to the 'parse' method is the $rdata
portion of the request. 'parse' returns the ascii 'dotquad' IP address.

The actual DESCRIPTION from B<Net::DNS::ToolKit::RR::A> follows with
annotation about the CODE and what is passed to all resource methods from
the class loader.

The rest of this Template example is taken DIRECTLY from
B<Net::DNS::ToolKit::RR::A>, with comments added for clarity and to show the
CODE.

=over 4

=item * @stuff = $get->A(\$buffer,$offset);

  Get the contents of the resource record.

  USE: @stuff = $get->next(\$buffer,$offset);

  where: @stuff = (
  $newoff $name,$type,$class,$ttl,$rdlength,
  $netaddr );

All except the last item, B<$netaddr>, is provided by
the class loader, B<Net::DNS::ToolKit::RR>. The code in this method knows
how to retrieve B<$netaddr>.

  input:        pointer to buffer,
                offset into buffer
  returns:      offset to next resource,
                @common RR elements,
                packed IPv4 address 
                  in network order

  NOTE: convert IPv4 address to dot quad text
        using Net::DNS::ToolKit::inet_ntoa

  ------------------------------------------

  The get function is passed a pointer to the buffer
  and an offset within the buffer to RDATA. It is
  expected to return the RDATA in the appropriate
  format as provided in the relevant RFC.

The call to 'get' from the class loader looks like this:

  $netaddr = $classloader->get(\$buffer,$offset);

Implementation for A RR's:

  sub get {
    my($self,$bp,$offset) = @_;
    $offset += INT16SZ;	# don't need rdlength
    my($netaddr,$newoff) = getIPv4($bp,$offset);
    return ($newoff,$netaddr);
  }

=cut

sub get {
  my($self,$bp,$offset) = @_;
  $offset += INT16SZ;	# don't need rdlength
  my($netaddr,$newoff) = getIPv4($bp,$offset);
  return ($newoff,$netaddr);
}

=item * ($newoff,@dnptrs)=$put->A(\$buffer,$offset,\@dnptrs,
	$name,$type,$class,$ttl,$netaddr);

Append an A record to $buffer.

  where @common = (
	$name,$type,$class,$ttl);

The method will insert the $rdlength and $netaddr, then
pass through the updated pointer to the array of compressed names            

The class loader, B<Net::DNS::ToolKit::RR>, inserts the @common elements and
returns updated @dnptrs. This module knows how to insert its RDATA and
calculate the $rdlength.

  input:        pointer to buffer,
                offset (normally end of buffer), 
                pointer to compressed name array,
                @common RR elements,
                packed IPv4 address
                  in network order
  output:       offset to next RR,
                new compressed name pointer array,
           or   empty list () on error.

  ------------------------------------------

The put function is passed a pointer to the buffer an offset into the buffer
(normally the end of buffer) and a pointer to an array of previously
compressed names. It is expected to append the correct RDLENGTH and 
RDATA to the buffer and return an offset to the next RR (usually the end of
buffer) as well as a new array of compressed names
or the one to which it has a pointer if there are no names added to the
buffer by this RR record method.

The call passed to 'put' by the class loader looks like this:

  $newoff = $classloader->put(\$buffer,$offset,\@dnptrs,@rdata);

Implementation for A RR's:

  sub put {
    return () unless @_;	# always return on error
    my($self,$bp,$off,$dnp,$netaddr) = @_;
    return () unless  
  	($off = put16($bp,$off,NS_INADDRSZ));
    return(putIPv4($bp,$off,$netaddr), @$dnp);
  }

Implementation for NS RR's: This method calculates $rdlength

  sub put {
    return () unless @_;    # always return on error
    my($self,$bp,$off,$dnp,$nsdname) = @_;
    my $rdlp = $off;        # save pointer to rdlength
    return () unless        # check for valid offset and get
      ($off = put16($bp,$off,0)) &&   # offset to name space
      (@_ = dn_comp($bp,$off,\$nsdname,$dnp));
    # new offset is first item in @_
    # rdlength = new offset - previous offset
    put16($bp,$rdlp, $_[0] - $off); 
    return @_;
  }

=cut

sub put {
  return () unless @_;	# always return on error
  my($self,$bp,$off,$dnp,$netaddr) = @_;
  return () unless  
	($off = put16($bp,$off,NS_INADDRSZ));
  return(putIPv4($bp,$off,$netaddr), @$dnp);
}

=item * (@COMMON,$IPaddr) = $parse->A(@common,$netaddr);

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

Resource Record B<A> returns $rdata containing a packed IPv4 network
address. The parse operation would be:

input:

  name       foo.bar.com
  type       1  
  class      1  
  ttl        123
  rdlength   4  
  rdata      a packed IPv4 address

output:

  name       foo.bar.com
  type       T_A 
  class      C_IN
  ttl        2m 3s
  rdlength   4   
  rdata      192.168.20.40

  ------------------------------------------

  The parse function is passed the RDATA for its type.
  It expected to convert the RDATA into human readable
  form and return it.

  $IPaddress = $classloader->parse($netaddr);

Implementation for A RR's:

  sub parse {
    shift;	# $self
    inet_ntoa(shift);
  }

NOTE: while the B<A> record does not return domain records, it is important
that developers remember to append a '.' to domain names which are text
formatted. i.e. foo.bar.com becomes foo.bar.com. when text formatted to
conform the record format for DNS files.

=back

=cut

sub parse {
  shift;	# $self
  inet_ntoa(shift);
}

=head1 CODE for THIS MODULE

The code in this module (for an 'A' resource record) without the comments is
pretty compact and looks like this:

  package Net::DNS::ToolKit::RR::A;

  use strict;
  use Carp;
  # The functions needed for 'A' records
  # are 'put16', 'getIPv4', putIPv4, inet_aton,
  # and inet_ntoa.  Other RR types will need 
  # different and/or additional functions. 

  use Net::DNS::ToolKit qw(
        put16
        getIPv4
        putIPv4
        inet_aton
        inet_ntoa
  );
  use Net::DNS::Codes qw(:constants);
  use vars qw($VERSION);
  require Socket;

  $VERSION = do { my @r = (q$Revision: 0.01 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

  =head1 NAME
  B<Net::DNS::ToolKit::RR::A>

  =head1 SYNOPSIS
	(removed for brevity)

  =head1 DESCRIPTION
	(removed for brevity)

  =over 4

  =item * @stuff = $get->A(\$buffer,$offset);
	(removed for brevity)

  =cut

  sub get {
    my($self,$bp,$offset) = @_;
    $offset += INT16SZ;	# don't need rdlength
    my($netaddr,$newoff) = getIPv4($bp,$offset);
    return ($newoff,$netaddr);
  }

  =item * ($newoff,@dnptrs)=$put->A(\$buffer,$offset,\@dnptrs,
	@common, $rdlength,$netaddr);  
	(removed for brevity)

  sub put {
    return () unless @_;	# always return on error
    my($self,$bp,$off,$dnp,$netaddr) = @_;
    return () unless  
  	($off = put16($bp,$off,NS_INADDRSZ));
    return(putIPv4($bp,$off,$netaddr), @$dnp);
  }

  =cut


  =item * (@COMMON,$IPaddr)=$parse->A(@common,$netaddr);
	(removed for brevity)

  =cut

  sub parse {
    shift;      # $self
    inet_ntoa(shift);
  }

=head1 TEST ROUTINES

See: t/Template.t in this distribution.


See: t/NS.t in the Net::DNS::Toolkit distribution for an example of a test
routine that is more complex as well as embedded debugging routines which
are commented out.

And.... what follows...

=head1 DEPENDENCIES

	Net::DNS::ToolKit
	Net::DNS::Codes
	any others you require
	for your new RR extension

=head1 EXPORT

	none

=head1 AUTHOR

Your Name <your@emailaddy.com>

=head1 COPYRIGHT

Portions copyright 2003, Michael Robinton <michael@bizsystems.com>

Copyright 20xx, Your Name <your@emailaddy.com>
   
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
   
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
   
You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=head1 See also:

Net::DNS::Codes(3), Net::DNS::ToolKit(3), Net::DNS::ToolKit::RR::A(3)

=cut

1;
