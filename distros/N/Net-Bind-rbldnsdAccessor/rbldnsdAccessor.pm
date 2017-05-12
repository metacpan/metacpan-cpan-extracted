package Net::Bind::rbldnsdAccessor;

use strict;
#use diagnostics;

use vars qw(@ISA $VERSION @EXPORT_OK %EXPORT_TAGS);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);

$VERSION = do { my @r = (q$Revision: 0.05 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

%EXPORT_TAGS = (
    isc_constants	=> [qw(
	ISC_R_SUCCESS ISC_R_NOMEMORY ISC_R_TIMEDOUT ISC_R_NOTHREADS
	ISC_R_ADDRNOTAVAIL ISC_R_ADDRINUSE ISC_R_NOPERM ISC_R_NOCONN
	ISC_R_NETUNREACH ISC_R_HOSTUNREACH ISC_R_NETDOWN ISC_R_HOSTDOWN
	ISC_R_CONNREFUSED ISC_R_NORESOURCES ISC_R_EOF ISC_R_BOUND
	ISC_R_RELOAD ISC_R_LOCKBUSY ISC_R_EXISTS ISC_R_NOSPACE
	ISC_R_CANCELED ISC_R_NOTBOUND ISC_R_SHUTTINGDOWN ISC_R_NOTFOUND
	ISC_R_UNEXPECTEDEND ISC_R_FAILURE ISC_R_IOERROR ISC_R_NOTIMPLEMENTED
	ISC_R_UNBALANCED ISC_R_NOMORE ISC_R_INVALIDFILE ISC_R_BADBASE64
	ISC_R_UNEXPECTEDTOKEN ISC_R_QUOTA ISC_R_UNEXPECTED ISC_R_ALREADYRUNNING
	ISC_R_IGNORE ISC_R_MASKNONCONTIG ISC_R_FILENOTFOUND ISC_R_FILEEXISTS
	ISC_R_NOTCONNECTED ISC_R_RANGE ISC_R_NOENTROPY ISC_R_MULTICAST
	ISC_R_NOTFILE ISC_R_NOTDIRECTORY ISC_R_QUEUEFULL ISC_R_FAMILYMISMATCH
	ISC_R_FAMILYNOSUPPORT ISC_R_BADHEX ISC_R_TOOMANYOPENFILES
	ISC_R_NOTBLOCKING ISC_R_UNBALANCEDQUOTES ISC_R_INPROGRESS
	ISC_R_CONNECTIONRESET ISC_R_SOFTQUOTA ISC_R_BADNUMBER 
	ISC_R_DISABLED ISC_R_MAXSIZE ISC_R_BADADDRESSFORM
    )],
    test	=> [qw(
	RBLF_DLEN
	rblf_strncpy
	rblf_load_dnstest
	rblf_dump_packet
    )],
);

@EXPORT_OK = (qw(
	cons_str
	rblf_query
	rblf_next_answer
	rblf_create_zone
	rblf_reinit
    ),	@{$EXPORT_TAGS{isc_constants}},
	@{$EXPORT_TAGS{test}},
);

bootstrap Net::Bind::rbldnsdAccessor $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

# Below is stub documentation for your module. You better edit it!

=head1 NAME

Net::Bind::rbldnsdAccessor - access rbldnsd files with Perl or BIND

=head1 SYNOPSIS

  use Net::Bind::rbldnsdAccessor qw(
	:isc_constants
	cons_str
	rblf_create_zone
	rblf_query
	rblf_next_answer
	rblf_reinit
  );	

=head1 DESCRIPTION

B<Net::Bind::rbldnsdAccessor> provides direct access to B<rbldnsd> data
files with Perl and BIND-9.1+. The build process creates a library file
suitable for use with BIND 9.1+ that allows the B<named> daemon to directly access B<rbldnsd>
files and use the same memory caching methods for those records to reduce
the storage requirements for large DNSBL zones by several orders of
magnitude.

i.e. The spamcannibal zone file as of this writing consumes 300 megs of
memory when loaded into BIND. It consumes under 400k of memory loaded into
rbldnsd. When compiled into BIND, rbldnsdaccessor extension checks for
zonefile updates every 60 seconds.

The available Perl functions are as follows:

=over 4

=item * $constant = [constant_name]();

Return the value of the constant or error.

  i.e. ISC_R_DISABLED();

  The following constants are exported with :isc_constants

ISC_R_SUCCESS ISC_R_NOMEMORY ISC_R_TIMEDOUT ISC_R_NOTHREADS
ISC_R_ADDRNOTAVAIL ISC_R_ADDRINUSE ISC_R_NOPERM ISC_R_NOCONN
ISC_R_NETUNREACH ISC_R_HOSTUNREACH ISC_R_NETDOWN ISC_R_HOSTDOWN
ISC_R_CONNREFUSED ISC_R_NORESOURCES ISC_R_EOF ISC_R_BOUND
ISC_R_RELOAD ISC_R_LOCKBUSY ISC_R_EXISTS ISC_R_NOSPACE
ISC_R_CANCELED ISC_R_NOTBOUND ISC_R_SHUTTINGDOWN ISC_R_NOTFOUND
ISC_R_UNEXPECTEDEND ISC_R_FAILURE ISC_R_IOERROR ISC_R_NOTIMPLEMENTED
ISC_R_UNBALANCED ISC_R_NOMORE ISC_R_INVALIDFILE ISC_R_BADBASE64
ISC_R_UNEXPECTEDTOKEN ISC_R_QUOTA ISC_R_UNEXPECTED ISC_R_ALREADYRUNNING
ISC_R_IGNORE ISC_R_MASKNONCONTIG ISC_R_FILENOTFOUND ISC_R_FILEEXISTS
ISC_R_NOTCONNECTED ISC_R_RANGE ISC_R_NOENTROPY ISC_R_MULTICAST
ISC_R_NOTFILE ISC_R_NOTDIRECTORY ISC_R_QUEUEFULL ISC_R_FAMILYMISMATCH
ISC_R_FAMILYNOSUPPORT ISC_R_BADHEX ISC_R_TOOMANYOPENFILES
ISC_R_NOTBLOCKING ISC_R_UNBALANCEDQUOTES ISC_R_INPROGRESS
ISC_R_CONNECTIONRESET ISC_R_SOFTQUOTA ISC_R_BADNUMBER 
ISC_R_DISABLED ISC_R_MAXSIZE ISC_R_BADADDRESSFORM

=item * $string = cons_str($constant_val);

Return a description of the constant or error.

  input:	constant or error value
  returns:	descriptive string
	    or	literal 'undef' if bad value

=cut

my %description = (
	&ISC_R_SUCCESS			=>	'success',
	&ISC_R_NOMEMORY			=>	'out of memory',
	&ISC_R_TIMEDOUT			=>	'timed out',
	&ISC_R_NOTHREADS		=>	'no available threads',
	&ISC_R_ADDRNOTAVAIL		=>	'address not available',
	&ISC_R_ADDRINUSE		=>	'address in use',
	&ISC_R_NOPERM			=>	'permission denied',
	&ISC_R_NOCONN			=>	'no pending connections',
	&ISC_R_NETUNREACH		=>	'network unreachable',
	&ISC_R_HOSTUNREACH		=>	'host unreachable',
	&ISC_R_NETDOWN			=>	'network down',
	&ISC_R_HOSTDOWN			=>	'host down',
	&ISC_R_CONNREFUSED		=>	'connection refused',
	&ISC_R_NORESOURCES		=>	'not enough free resources',
	&ISC_R_EOF			=>	'end of file',
	&ISC_R_BOUND			=>	'socket already bound',
	&ISC_R_RELOAD			=>	'reload',
	&ISC_R_LOCKBUSY			=>	'lock busy',
	&ISC_R_EXISTS			=>	'already exists',
	&ISC_R_NOSPACE			=>	'ran out of space',
	&ISC_R_CANCELED			=>	'operation canceled',
	&ISC_R_NOTBOUND			=>	'socket is not bound',
	&ISC_R_SHUTTINGDOWN		=>	'shutting down',
	&ISC_R_NOTFOUND			=>	'not found',
	&ISC_R_UNEXPECTEDEND		=>	'unexpected end of input',
	&ISC_R_FAILURE			=>	'generic failure',
	&ISC_R_IOERROR			=>	'I/O error',
	&ISC_R_NOTIMPLEMENTED		=>	'not implemented',
	&ISC_R_UNBALANCED		=>	'unbalanced parentheses',
	&ISC_R_NOMORE			=>	'no more',
	&ISC_R_INVALIDFILE		=>	'invalid file',
	&ISC_R_BADBASE64		=>	'bad base64 encoding',
	&ISC_R_UNEXPECTEDTOKEN		=>	'unexpected token',
	&ISC_R_QUOTA			=>	'quota reached',
	&ISC_R_UNEXPECTED		=>	'unexpected error',
	&ISC_R_ALREADYRUNNING		=>	'already running',
	&ISC_R_IGNORE			=>	'ignore',
	&ISC_R_MASKNONCONTIG            =>	'addr mask not contiguous',
	&ISC_R_FILENOTFOUND		=>	'file not found',
	&ISC_R_FILEEXISTS		=>	'file already exists',
	&ISC_R_NOTCONNECTED		=>	'socket is not connected',
	&ISC_R_RANGE			=>	'out of range',
	&ISC_R_NOENTROPY		=>	'out of entropy',
	&ISC_R_MULTICAST		=>	'invalid use of multicast',
	&ISC_R_NOTFILE			=>	'not a file',
	&ISC_R_NOTDIRECTORY		=>	'not a directory',
	&ISC_R_QUEUEFULL		=>	'queue is full',
	&ISC_R_FAMILYMISMATCH		=>	'address family mismatch',
	&ISC_R_FAMILYNOSUPPORT		=>	'AF not supported',
	&ISC_R_BADHEX			=>	'bad hex encoding',
	&ISC_R_TOOMANYOPENFILES		=>	'too many open files',
	&ISC_R_NOTBLOCKING		=>	'not blocking',
	&ISC_R_UNBALANCEDQUOTES		=>	'unbalanced quotes',
	&ISC_R_INPROGRESS		=>	'operation in progress',
	&ISC_R_CONNECTIONRESET		=>	'connection reset',
	&ISC_R_SOFTQUOTA		=>	'soft quota reached',
	&ISC_R_BADNUMBER		=>	'not a valid number',
	&ISC_R_DISABLED			=>	'disabled',
	&ISC_R_MAXSIZE			=>	'max size',
	&ISC_R_BADADDRESSFORM		=>	'invalid address format',
	&ISC_R_NRESULTS 		=>	'number of results',
);

sub cons_str {
  my $con = shift;
  return 'undef' unless $con && exists $description{$con};
  return $description{$con};
}

1;
__END__

=item * ($isc_response) = rblf_create_zone($zname,$ztype,$file1,...);

Load an rbldnsd zone from file.

  input:	zone name,
		zone type
		file list...
  returns:	isc_response code
	one of	ISC_R_SUCCESS
	    or	a failure code


  zone types are one of:
	ip4set
	ip4trie
	ip4tset
	dnset
	generic
	combined

  acl sets are not supported

=item * ($answers,$isc_return_code) = rblf_query(#domain);

Query the rbldnsd database for DOMAIN in ZONE.

  input:	domain name to lookup
  returns:	number of answers,
		isc_return code

  i.e.	$answers = rblf_query('myzone.com');

=item * ($type,$ttl,$rdl,$rdata,$off) = rblf_next_answer();

Parse and return the next answer from the DNS message.

  input:	none
  returns:	TYPE,
		TTL,
		rdata LENGTH
		RDATA (uncompressed)
		offset of next answer

=item * rblf_reinit();

Reinitialize the module to its virgin state, dropping all zones and all
allocated memory.

  input:	none
  returns:	nothing

=cut

#=item * TEST ONLY ($answers,$offset) = rblf_load_dnstest($dns_message);
#
#Load a DNS message into the answer parser for testing.
#
#  input:	a dns message
#  returns:	number of answers,
#		offset of first answer
#	    or  undef/empty array on error
#
#=item * TEST ONLY ($len,$packet,$p_buf,$p_cur,$p_sans,$p_endp,$coff,$saoff)=rblf_dump_packet();
#
#Dump the internal dummy packet buffer.
#
#  input:	none
#  returns:	lenth of buffer,
#		buffer contents,
#		pointer start of buffer,
#		pointer current,
#		pointer start of answers,
#		pointer end buffer,
#		current offset,
#		answers offset
#
#=item * TEST ONLY ($len,$string) = rblf_strncpy($src,$max,$c);
#
#Copies $src to an internal buffer and returns it as $string of length
#RBLF_DLEN. $string will be NULL terminated at the end of the copied data and
#trailing filled with character $c. Will copy the lesser of $src or $max 
#characters. The string will ALWAYS be NULL terminated.
#
#  input:        string to copy from,
#                max characters to copy,
#                fill character
#  returns:      #characters copied,
#                entire internal buffer

=pod

=back

=head1 INSTALLATION

  1)	Perl Makefile.PL
  2)	enter the full path to {/rbldnsd/source/directory}
  3)	make
  4)	make test
  5)	make install ONLY if building for Perl

Complete these steps only if building for BIND.

In the source tree:

  6)	copy librbldnsdaccessor.a, rbldnsdaccessor.c, and
	rbldnsdaccessor.h to {/bind/source/directory}/bin/named
  7)	Alter {/bind/source/directory}/bin/named/Makefile.in.
	Add rbldnsdaccessor.@O@ and librbldnsdaccessor.@A@
	to DBDRIVER_OBJS

	IF you have included compression/decompression support
	(zlib) then you also need to add something like -lz
	to DBDRIVER_LIBS and you may need to add the linker
	path (-L/usr/local/lib) or similar as well as
	(-I/usr/local/includes) to DBDRIVER_INCLUDES depending
	where zlib is installed on your system.

  8)	Alter {/bind/source/directory}/bin/named/main.c
	below where it says "#include "xxdb.h" add the
	line "#include "rbldnsdaccessor.h"". Below where
	it says "xxdb_init();", add the line "rbldnsd_init();", 
	and finally below where is says "xxdb_clear" add,
	add the line "rbldnsd_clear();"

Now you should hopefully be able to build as usual; first configure
and then make.

=head1 BIND CONFIGURATION FILE ENTRY

The syntax of the bind configuration file entry for using rbldnsd files is 
as follows:

  zone "my.zonename.com" {
	type master;
	database "rbldnsd zone-type filelist ...";
  };

Where the zone-type is one of:

        ip4set
        ip4trie
        ip4tset
        dnset
        generic
        combined

See the rbldnsd documentation for specific information about the zone-types
and file formats.

=head1 EXPORT_OK

	:isc_constants
	cons_str
	rblf_create_zone
	rblf_query
	rblf_next_answer
	rblf_reinit

=head1 PREREQUISITES

	for testing:
	  Net::DNS::Codes
	  Net::DNS::ToolKit

	source for rbldnsd-0.996a or better

	[optionally] source for bind-9.1.0+

The documents with BIND suggest that 9.1.0 has the necessary api to work with
librbldnsdaccessor.a. This has only been tested against BIND-9.3.2-P1

=head1 COPYRIGHT and LICENSE

 Copyright 2006, Michael Robinton, michael@bizsystems.com

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

=head1 AUTHOR

Michael Robinton <michael@bizsystems.com>

=head1 See BIND 9 documentation, man rbldnsd

=cut

1;
