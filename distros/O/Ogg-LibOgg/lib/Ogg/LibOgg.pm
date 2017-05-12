package Ogg::LibOgg;

use 5.008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = 
  qw (
       make_ogg_packet
       make_ogg_stream_state
       make_ogg_page
       make_ogg_sync_state
       ogg_stream_init
       ogg_read_page
       ogg_page_bos
       ogg_page_eos
       ogg_page_checksum_set
       ogg_page_continued
       ogg_page_granulepos
       ogg_page_packets
       ogg_page_pageno
       ogg_page_serialno
       ogg_stream_clear
       ogg_stream_reset
       ogg_stream_reset_serialno
       ogg_stream_destroy
       ogg_stream_check
       ogg_page_version
       ogg_packet_clear
       ogg_stream_packetin
       ogg_stream_pageout
       ogg_stream_flush
       ogg_sync_init
       ogg_sync_clear
       ogg_sync_reset
       ogg_sync_destroy
       ogg_sync_check
       ogg_sync_buffer
       ogg_sync_wrote
       ogg_sync_pageseek
       ogg_sync_pageout
       ogg_stream_pagein
       ogg_stream_packetout
       ogg_stream_packetpeek
       get_ogg_page
    );

# This allows declaration	use Ogg::LibOgg ':all';
our %EXPORT_TAGS = ( 'all' => \@EXPORT_OK );

## We export none by default
our @EXPORT = qw();

our $VERSION = '0.02';

## Load the XS code
require XSLoader;
XSLoader::load('Ogg::LibOgg', $VERSION);


1;


__END__


=head1 NAME

Ogg::LibOgg - XS Code for Ogg bindings for Perl.

=head1 SYNOPSIS

  use Ogg::LibOgg;
  my $filename = "t/test.ogg";
  open $fd, $filename or die "Can't open $filename: $!";
  ## Make Ogg Packet
  my $op = Ogg::LibOgg::make_ogg_packet();
  ## Make Ogg Stream State
  my $os = Ogg::LibOgg::make_ogg_stream_state();
  ## Make Ogg Page
  my $og = Ogg::LibOgg::make_ogg_page();
  ## Make Ogg Sync State
  my $oy = Ogg::LibOgg::make_ogg_sync_state();
  ## Ogg Sync Init
  Ogg::LibOgg::ogg_sync_init($oy); # this should be == 0
  ## Ogg Read Page (this is a custom wrapper, please read the perldoc)
  Ogg::LibOgg::ogg_read_page($fd, $oy, $og); # == 0, 
  ## Ogg Page Serial Number
  my $slno = Ogg::LibOgg::ogg_page_serialno($og);
  ..etc..
  close $fd;


=head1 DESCRIPTION

Ogg::LibOgg let you call the libogg functions directly and the glue is written in XS. 
Please read LibOgg.xs to understand the implementation.

=head2 EXPORT

None by default. Please use Ogg::LibOgg ':all' to export everything to the current 
namespace.

=head1 Functions (malloc)

Memory Allocation for the Ogg Structures


=head2 make_ogg_packet

Creates an Ogg Packet.

-Input:
  Void

-Output:
  Memory address of Ogg Packet.


=head2 make_ogg_stream_state

Creates an Ogg Stream State.

-Input:
  Void

-Output:
  Memory address of Ogg Stream State.


=head2 make_ogg_page

Creates an Ogg Page.

-Input:
  Void

-Output:
  Memory address of Ogg Page.


=head2 make_ogg_sync_state

Creates an Ogg Sync State.

-Input:
  Void

-Output:
  Memory address og Ogg Sync State.


=head1 Functions (Bitstream Primitives)


=head2 ogg_stream_init

This function is used to initialize an ogg_stream_state struct and 
allocates appropriate memory in preparation for encoding or decoding. 
L<http://www.xiph.org/ogg/doc/libogg/ogg_stream_init.html>

-Input:
  ogg_stream_state (memory addr)
  serial number

-Output:
   0 if successful
  -1 if unsuccessful


=head2 ogg_read_page

This function is a B<wrapper around ogg_sync_pageout>. In an actual decoding loop, 
this function should be called first to ensure that the buffer is cleared. The 
example code below illustrates a clean reading loop which will fill and output pages. 

ogg_sync_pageout takes the data stored in the buffer of the ogg_sync_state struct
and inserts them into an ogg_page.

  if (ogg_sync_pageout(&oy, &og) != 1) {
	buffer = ogg_sync_buffer(&oy, 8192);
	bytes = fread(buffer, 1, 8192, stdin);
	ogg_sync_wrote(&oy, bytes);
  }

-Input:
  FILE *
  ogg_sync_state
  ogg_page

-Output:
  -1 buffer overflow or internal error (status of ogg_sync_wrote)
   0 all other cases


=head2 ogg_page_bos

Indicates whether this page is at the beginning of the logical bitstream.
L<http://www.xiph.org/ogg/doc/libogg/ogg_page_bos.html>

-Input:
  ogg_page

-Output:
  > 0 if this page is the beginning of a bitstream.
  0 if this page is from any other location in the stream.


=head2 ogg_page_eos

Indicates whether this page is at the end of the logical bitstream. 
L<http://www.xiph.org/ogg/doc/libogg/ogg_page_eos.html>

-Input:
  ogg_page

-Output:
  > 0 if this page is the beginning of a bitstream.
  0 if this page is from any other location in the stream.


=head2 ogg_page_checksum_set

Checksums an ogg_page. 
L<http://www.xiph.org/ogg/doc/libogg/ogg_page_checksum_set.html>

(Not *SURE* why in the ogg official doc, they have given the
function definition as 'int ogg_page_checksum_set(og)', it should
be actuall 'void ogg_page_checksum_set(og)').

-Input:
  ogg_page

-Output:
  void


=head2 ogg_page_continued

Indicates whether this page contains packet data which has been continued from 
the previous page. L<http://www.xiph.org/ogg/doc/libogg/ogg_page_continued.html>

-Input:
  ogg_page

-Output:
  int


=head2 ogg_page_granulepos

Returns the exact granular position of the packet data contained at the end of 
this page. L<http://www.xiph.org/ogg/doc/libogg/ogg_page_granulepos.html>

-Input:
  ogg_page

-Output:
  n is the specific last granular position of the decoded data contained in the page.


=head2 ogg_page_packets

Returns the number of packets that are completed on this page.

L<http://www.xiph.org/ogg/doc/libogg/ogg_page_packets.html>

-Input:
  ogg_page

-Output:
  1 If a page consists of a packet begun on a previous page, 
  != 0 a new packet begun (but not completed) on this page,

  0 If a page happens to be a single packet that was begun on a previous page, 
  != 0 and spans to the next page


=head2 ogg_page_pageno

Returns the sequential page number. 
L<http://www.xiph.org/ogg/doc/libogg/ogg_page_pageno.html>

-Input:
  ogg_page

-Output:
  n, is the page number for this page.


=head2 ogg_page_serialno

Returns the unique serial number for the logical bitstream of this page. 
Each page contains the serial number for the logical bitstream that it belongs to. 
L<http://www.xiph.org/ogg/doc/libogg/ogg_page_serialno.html>

-Input:
  ogg_page

-Output:
  n, where n is the serial number for this page.


=head2 ogg_stream_clear

This function clears and frees the internal memory used by the ogg_stream_state 
struct, but does not free the structure itself.
L<http://www.xiph.org/ogg/doc/libogg/ogg_stream_clear.html>

-Input:
  ogg_stream_state

-Output:
  0 is always returned


=head2 ogg_stream_reset

This function sets values in the ogg_stream_state struct back to initial values. 
L<http://www.xiph.org/ogg/doc/libogg/ogg_stream_reset.html>

-Input:
  ogg_stream_state

-Output:
  0, success
  != 0, internal error


=head2 ogg_stream_reset_serialno

Similar to ogg_stream_reset, but it also it sets the stream serial number to 
the given value. L<http://www.xiph.org/ogg/doc/libogg/ogg_stream_reset_serialno.html>

-Input:
  ogg_stream_state
  serialno

-Output:
  0, success
  != 0, internal error


=head2 ogg_stream_destroy

This function frees the internal memory used by the ogg_stream_state struct as well as 
the structure itself. L<http://www.xiph.org/ogg/doc/libogg/ogg_stream_destroy.html>

-Input:
  ogg_stream_state

-Output:
  0, always


=head2 ogg_stream_check

This function is used to check the error or readiness condition of an ogg_stream_state 
structure. L<http://www.xiph.org/ogg/doc/libogg/ogg_stream_check.html>

-Input:
  ogg_stream_state

-Output:
  0, if the ogg_stream_state structure is initialized and ready.
  != 0, never initialized, or if an unrecoverable internal error occurred 


=head2 ogg_page_version

This function returns the version of ogg_page used in this page. 
L<http://www.xiph.org/ogg/doc/libogg/ogg_page_version.html>

-Input:
  ogg_page

-Output:
  n, is the version number (for current ogg, 0 is always returned,
     else error)


=head2 ogg_packet_clear

his function clears the memory used by the ogg_packet struct, but does not 
free the structure itself. Don't call it directly.
L<http://www.xiph.org/ogg/doc/libogg/ogg_packet_clear.html>

-Input:
  ogg_packet

@Ouput:
  void


=head1 Functions (Encoding)


=head2 ogg_stream_packetin

This function submits a packet to the bitstream for page encapsulation. After this 
is called, more packets can be submitted, or pages can be written out.
L<http://www.xiph.org/ogg/doc/libogg/ogg_stream_packetin.html>

-Input:
  ogg_stream_state
  ogg_packet

-Output:
   0, on success
  -1, on internal error


=head2 ogg_stream_pageout

This function forms packets into pages, this would be called after using ogg_stream_packetin().
L<http://www.xiph.org/ogg/doc/libogg/ogg_stream_pageout.html>

-Input:
  ogg_stream_state
  ogg_page

-Output:
  0, insufficient data or internal error
  != 0, page has been completed and returned.


=head2 ogg_stream_flush

This function checks for remaining packets inside the stream and forces remaining 
packets into a page, regardless of the size of the page.
L<http://www.xiph.org/ogg/doc/libogg/ogg_stream_flush.html>

-Input:
  ogg_stream_state
  ogg_page

-Output:
  0, means that all packet data has already been flushed into pages
  != 0, means that remaining packets have successfully been flushed into the page.


=head1 Functions (Decoding)


=head2 ogg_sync_init

ogg sync init, This function is used to initialize an ogg_sync_state 
struct to a known initial value in preparation for manipulation of an 
Ogg bitstream. L<http://www.xiph.org/ogg/doc/libogg/ogg_sync_init.html>

-Input: 
  ogg_sync_state (memory addr)

-Output:
  0 (always)


=head2 ogg_sync_clear

This function is used to free the internal storage of an ogg_sync_state 
struct and resets the struct to the initial state.
L<http://www.xiph.org/ogg/doc/libogg/ogg_sync_clear.html>

-Input:
  ogg_sync_state

-Output:
  0, always


=head2 ogg_sync_reset

This function is used to reset the internal counters of the ogg_sync_state struct 
to initial values. L<http://www.xiph.org/ogg/doc/libogg/ogg_sync_reset.html>

-Input:
  ogg_sync_state

-Output:
  0, always


=head2 ogg_sync_destroy

This function is used to destroy an ogg_sync_state struct and free all memory used.
L<http://www.xiph.org/ogg/doc/libogg/ogg_sync_destroy.html>

-Input:
  ogg_sync_state

@Ouput:
  0, always


=head2 ogg_sync_check

This function is used to check the error or readiness condition of an ogg_sync_state 
structure. L<http://www.xiph.org/ogg/doc/libogg/ogg_sync_check.html>

-Input:
  ogg_sync_state

-Output:
  0, is returned if the ogg_sync_state structure is initialized and ready.
  != 0, if the structure was never initialized, or if an unrecoverable internal error


=head2 ogg_sync_buffer

This function is used to provide a properly-sized buffer for writing. 
L<http://www.xiph.org/ogg/doc/libogg/ogg_sync_buffer.html>

-Input:
  ogg_sync_state
  size

-Output:
  Returns a pointer to the newly allocated buffer or NULL on error


=head2 ogg_sync_wrote

This function is used to tell the ogg_sync_state struct how many bytes we 
wrote into the buffer. 
L<http://www.xiph.org/ogg/doc/libogg/ogg_sync_wrote.html>

-Input:
  ogg_sync_state
  bytes

-Output:
  -1 if the number of bytes written overflows the internal storage of 
     the ogg_sync_state struct or an internal error occurred. 
   0 in all other cases.


=head2 ogg_sync_pageseek

This function synchronizes the ogg_sync_state struct to the next ogg_page. 
L<http://www.xiph.org/ogg/doc/libogg/ogg_sync_pageseek.html>

-Input:
  ogg_sync_state
  ogg_page

-Output:
 -n means that we skipped n bytes within the bitstream.
  0 means that we need more data, or than an internal error occurred.
  n means that the page was synced at the current location, 
    with a page length of n bytes. 


=head2 ogg_sync_pageout

This function takes the data stored in the buffer of the ogg_sync_state struct
and inserts them into an ogg_page. In an actual decoding loop, this function 
should be called first to ensure that the buffer is cleared. 
L<http://www.xiph.org/ogg/doc/libogg/ogg_sync_pageout.html>

-Input:
  ogg_sync_state
  ogg_page

-Output:
  -1 returned if stream has not yet captured sync (bytes were skipped).
   0 returned if more data needed or an internal error occurred.
   1 indicated a page was synced and returned.


=head2 ogg_stream_pagein

This function adds a complete page to the bitstream. In a typical decoding situation, 
this function would be called after using ogg_sync_pageout to create a valid ogg_page 
struct. L<http://www.xiph.org/ogg/doc/libogg/ogg_stream_pagein.html>

-Input:
  ogg_stream_state
  ogg_page

-Output:
  -1 indicates failure.
   0 means that the page was successfully submitted to the bitstream.


=head2 ogg_stream_packetout

This function assembles a data packet for output to the codec decoding engine. 
The data has already been submitted to the ogg_stream_state and broken into segments. 
Each successive call returns the next complete packet built from those segments.
L<http://www.xiph.org/ogg/doc/libogg/ogg_stream_packetout.html>

-Input:
  ogg_stream_state
  ogg_packet

-Output:
  -1 if we are out of sync and there is a gap in the data.
   0 insufficient data available to complete a packet, or unrecoverable internal error occurred.
   1 if a packet was assembled normally. op contains the next packet from the stream.


=head2 ogg_stream_packetpeek

This function attempts to assemble a raw data packet and returns it without advancing 
decoding. L<http://www.xiph.org/ogg/doc/libogg/ogg_stream_packetpeek.html>

-Input:
  ogg_stream_state
  ogg_packet

-Output:
  -1, no packet available due to lost sync or a hole in the data.
   0, insufficient data available to complete a packet, or on unrecoverable internal error
   1, packet is available


=head1 CAVEATS

B<ogg_page> and B<ogg_packet> structs mostly point to storage in libvorbis/libtheora. 
They're never freed or manipulated directly. You may get a malloc error doing so.

B<oggpack_buffer> struct which is used with libogg's bitpacking functions is not exposed, 
as you should never need to directly access anything in this structure. So are the
functions manipulating oggpack_buffer, they too are not exposed. 
L<http://www.xiph.org/ogg/doc/libogg/oggpack_buffer.html>

B<ogg_stream_iovecin>, C<not implemented> as this function submits packet data (in the form of an 
array of ogg_iovec_t, rather than using an ogg_packet structure) to the bitstream for page 
encapsulation. L<http://www.xiph.org/ogg/doc/libogg/ogg_stream_iovecin.html>


=head1 AUTHORS

Vigith Maurice <vigith@yahoo-inc.com> L<www.vigith.com>


=head1 COPYRIGHT

Vigith Maurice (C) 2011

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.

=cut

# perl -lne '$/=undef;print $1 while $_ =~ m!(^=head.*?=cut)!msg' LibOgg.xs | sed -e 's/=cut//' >> lib/Ogg/LibOgg.pm
