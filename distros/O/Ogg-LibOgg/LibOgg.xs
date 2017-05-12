#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include<stdio.h>
#include <ogg/ogg.h>

typedef PerlIO *        OutputStream;
typedef PerlIO *        InputStream;

#define OGG_BUF_SIZE 4096

MODULE = Ogg::LibOgg		PACKAGE = Ogg::LibOgg		PREFIX = Ogg_LibOgg_

PROTOTYPES: DISABLE

=head1 Ogg::LibOgg

XS Code for Ogg bindings for Perl.

=cut

=head1 Functions (malloc)

Memory Allocation for the Ogg Structures

=cut


=head2 make_ogg_packet

Creates an Ogg Packet.

-Input:
  Void

-Output:
  Memory address of Ogg Packet.

=cut
void
Ogg_LibOgg_make_ogg_packet()
  PREINIT:
    ogg_packet *memory;
  PPCODE:
    New(0, memory, 1, ogg_packet);  // it always satisfies with what we have asked
    XPUSHs(sv_2mortal(newSViv(PTR2IV(memory))));  // since i am using sv_2mortal, i don't have to worry about leaks

=head2 make_ogg_stream_state

Creates an Ogg Stream State.

-Input:
  Void

-Output:
  Memory address of Ogg Stream State.

=cut
void
Ogg_LibOgg_make_ogg_stream_state()
  PREINIT:
    ogg_stream_state *memory;
  PPCODE:
    New(0, memory, 1, ogg_stream_state);
    XPUSHs(sv_2mortal(newSViv(PTR2IV(memory))));


=head2 make_ogg_page

Creates an Ogg Page.

-Input:
  Void

-Output:
  Memory address of Ogg Page.

=cut
void
Ogg_LibOgg_make_ogg_page()
  PREINIT:
    ogg_page *memory;
  PPCODE:
    New(0, memory, 1, ogg_page);
    XPUSHs(sv_2mortal(newSViv(PTR2IV(memory))));


=head2 make_ogg_sync_state

Creates an Ogg Sync State.

-Input:
  Void

-Output:
  Memory address of Ogg Sync State.

=cut
void
Ogg_LibOgg_make_ogg_sync_state()
  PREINIT:
    ogg_sync_state *memory;
  PPCODE:
    New(0, memory, 1, ogg_sync_state);
    XPUSHs(sv_2mortal(newSViv(PTR2IV(memory))));


=head1 Functions (Bitstream Primitives)

=cut


=head2 ogg_stream_init

This function is used to initialize an ogg_stream_state struct and 
allocates appropriate memory in preparation for encoding or decoding. 
(http://www.xiph.org/ogg/doc/libogg/ogg_stream_init.html)

-Input:
  ogg_stream_state (memory addr)
  serial number

-Output:
   0 if successful
  -1 if unsuccessful

=cut
int 
ogg_stream_init(os, serialno)
    int		    os
    int		    serialno
  PREINIT:
    ogg_stream_state *_os;
  CODE:
    _os = INT2PTR(ogg_stream_state *, os);
    RETVAL = ogg_stream_init(_os, serialno);
  OUTPUT:
    RETVAL


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

=cut
int
Ogg_LibOgg_ogg_read_page(stream, oy, og)
    InputStream		stream    			    
    int			oy
    int 		og
  PREINIT:
     // search for stdio layers
     FILE *fp = PerlIO_findFILE(stream);
     ogg_sync_state *_oy;
     ogg_page *_og;
     size_t bytes;
     int ret;
     char *buffer;
  CODE:
    // check whether it is a valid file handler
    if (fp == (FILE*) 0 || fileno(fp) <= 0) {	
      Perl_croak(aTHX_ "Expected Open FILE HANDLER");
    }
    _oy = INT2PTR(ogg_sync_state *, oy);
    _og = INT2PTR(ogg_page *, og);   
    while(ogg_sync_pageout(_oy, _og) != 1) {
      buffer = ogg_sync_buffer(_oy, OGG_BUF_SIZE);
      bytes = fread(buffer, 1, OGG_BUF_SIZE, fp);
      if (bytes == 0) {
        XSRETURN_UNDEF;
      }
      ret = ogg_sync_wrote(_oy, bytes);
    }
    RETVAL = ret;
  OUTPUT:
    RETVAL


=head2 ogg_page_bos

Indicates whether this page is at the beginning of the logical bitstream.
(http://www.xiph.org/ogg/doc/libogg/ogg_page_bos.html)

-Input:
  ogg_page

-Output:
  > 0 if this page is the beginning of a bitstream.
  0 if this page is from any other location in the stream.

=cut
int
Ogg_LibOgg_ogg_page_bos(og)
    int		og
  PREINIT:
    ogg_page *_og;
  CODE:
    _og = INT2PTR(ogg_page *, og);
    RETVAL = ogg_page_bos(_og);
  OUTPUT:
    RETVAL

=head2 ogg_page_eos

Indicates whether this page is at the end of the logical bitstream. 
(http://www.xiph.org/ogg/doc/libogg/ogg_page_eos.html)

-Input:
  ogg_page

-Output:
  > 0 if this page is the beginning of a bitstream.
  0 if this page is from any other location in the stream.

=cut
int
Ogg_LibOgg_ogg_page_eos(og)
    int		og
  PREINIT:
    ogg_page *_og;
  CODE:
    _og = INT2PTR(ogg_page *, og);
    RETVAL = ogg_page_eos(_og);
  OUTPUT:
    RETVAL


=head2 ogg_page_checksum_set

Checksums an ogg_page. 
(http://www.xiph.org/ogg/doc/libogg/ogg_page_checksum_set.html)

(Not *SURE* why in the ogg official doc, they have given the
function definition as 'int ogg_page_checksum_set(og)', it should
be actuall 'void ogg_page_checksum_set(og)').

-Input:
  ogg_page

-Output:
  void

=cut
void
Ogg_LibOgg_ogg_page_checksum_set(og)
    int		og
  PREINIT:
    ogg_page *_og;
  CODE:
    _og = INT2PTR(ogg_page *, og);
    ogg_page_checksum_set(_og);


=head2 ogg_page_continued

Indicates whether this page contains packet data which has been continued from 
the previous page. (http://www.xiph.org/ogg/doc/libogg/ogg_page_continued.html)

-Input:
  ogg_page

-Output:
  int

=cut
int
Ogg_LibOgg_ogg_page_continued(og)
    int		og
  PREINIT:
    ogg_page *_og;
  CODE:
    _og = INT2PTR(ogg_page *, og);
    RETVAL = ogg_page_continued(_og);
  OUTPUT:
    RETVAL

=head2 ogg_page_granulepos

Returns the exact granular position of the packet data contained at the end of 
this page. (http://www.xiph.org/ogg/doc/libogg/ogg_page_granulepos.html)

-Input:
  ogg_page

-Output:
  n is the specific last granular position of the decoded data contained in the page.

=cut
ogg_int64_t
Ogg_LibOgg_ogg_page_granulepos(og)
    int		og
  PREINIT:
    ogg_page *_og;
  CODE:
    _og = INT2PTR(ogg_page *, og);
    RETVAL = ogg_page_granulepos(_og);
  OUTPUT:
    RETVAL


=head2 ogg_page_packets

Returns the number of packets that are completed on this page.

(http://www.xiph.org/ogg/doc/libogg/ogg_page_packets.html)

-Input:
  ogg_page

-Output:
  1 If a page consists of a packet begun on a previous page, 
  != 0 a new packet begun (but not completed) on this page,

  0 If a page happens to be a single packet that was begun on a previous page, 
  != 0 and spans to the next page

=cut
int
Ogg_LibOgg_ogg_page_packets(og)
    int		og
  PREINIT:
    ogg_page *_og;
  CODE:
    _og = INT2PTR(ogg_page *, og);
    RETVAL = ogg_page_packets(_og);
  OUTPUT:
    RETVAL 

=head2 ogg_page_pageno

Returns the sequential page number. 
(http://www.xiph.org/ogg/doc/libogg/ogg_page_pageno.html)

-Input:
  ogg_page

-Output:
  n, is the page number for this page.

=cut
long
Ogg_LibOgg_ogg_page_pageno(og)
    int		og
  PREINIT:
    ogg_page *_og;
  CODE:
    _og = INT2PTR(ogg_page *, og);
    RETVAL = ogg_page_pageno(_og);
  OUTPUT:
    RETVAL


=head2 ogg_page_serialno

Returns the unique serial number for the logical bitstream of this page. 
Each page contains the serial number for the logical bitstream that it belongs to. 
(http://www.xiph.org/ogg/doc/libogg/ogg_page_serialno.html)

-Input:
  ogg_page

-Output:
  n, where n is the serial number for this page.

=cut
int
Ogg_LibOgg_ogg_page_serialno(og)
    int		og
  PREINIT:
    ogg_page *_og;
    int n = 0;
  CODE:
    _og = INT2PTR(ogg_page *, og);
    n = ogg_page_serialno(_og);
    RETVAL = n;
  OUTPUT:
    RETVAL


=head2 ogg_stream_clear

This function clears and frees the internal memory used by the ogg_stream_state 
struct, but does not free the structure itself.
(http://www.xiph.org/ogg/doc/libogg/ogg_stream_clear.html)

-Input:
  ogg_stream_state

-Output:
  0 is always returned

=cut
int
Ogg_LibOgg_ogg_stream_clear(os)
    int		os
  PREINIT:
    ogg_stream_state *_os;
  CODE:
    _os = INT2PTR(ogg_stream_state *, os);
    RETVAL = ogg_stream_clear(_os);
  OUTPUT:
    RETVAL

=head2 ogg_stream_reset

This function sets values in the ogg_stream_state struct back to initial values. 
(http://www.xiph.org/ogg/doc/libogg/ogg_stream_reset.html)

-Input:
  ogg_stream_state

-Output:
  0, success
  != 0, internal error

=cut
int
Ogg_LibOgg_ogg_stream_reset(os)
    int		os
  PREINIT:
    ogg_stream_state *_os;
  CODE:
    _os = INT2PTR(ogg_stream_state *, os);
    RETVAL = ogg_stream_reset(_os);
  OUTPUT:
    RETVAL


=head2 ogg_stream_reset_serialno

Similar to ogg_stream_reset, but it also it sets the stream serial number to 
the given value. (http://www.xiph.org/ogg/doc/libogg/ogg_stream_reset_serialno.html)

-Input:
  ogg_stream_state
  serialno

-Output:
  0, success
  != 0, internal error

=cut
int
Ogg_LibOgg_ogg_stream_reset_serialno(os, slno)
    int		os
    int 	slno
  PREINIT:
    ogg_stream_state *_os;
  CODE:
    _os = INT2PTR(ogg_stream_state *, os);
    RETVAL = ogg_stream_reset_serialno(_os, slno);
  OUTPUT:
    RETVAL


=head2 ogg_stream_destroy

This function frees the internal memory used by the ogg_stream_state struct as well as 
the structure itself. (http://www.xiph.org/ogg/doc/libogg/ogg_stream_destroy.html)

-Input:
  ogg_stream_state

-Output:
  0, always

=cut
int
Ogg_LibOgg_ogg_stream_destroy(os)
    int		os
  PREINIT:
    ogg_stream_state *_os;
  CODE:
    _os = INT2PTR(ogg_stream_state *, os);
    RETVAL = ogg_stream_destroy(_os);
  OUTPUT:
    RETVAL


=head2 ogg_stream_check

This function is used to check the error or readiness condition of an ogg_stream_state 
structure. (http://www.xiph.org/ogg/doc/libogg/ogg_stream_check.html)

-Input:
  ogg_stream_state

-Output:
  0, if the ogg_stream_state structure is initialized and ready.
  != 0, never initialized, or if an unrecoverable internal error occurred 

=cut
int
Ogg_LibOgg_ogg_stream_check(os)
    int		os
  PREINIT:
    ogg_stream_state *_os;
  CODE:
    _os = INT2PTR(ogg_stream_state *, os);
    RETVAL = ogg_stream_check(_os);
  OUTPUT:
    RETVAL


=head2 ogg_page_version

This function returns the version of ogg_page used in this page. 
(http://www.xiph.org/ogg/doc/libogg/ogg_page_version.html)

-Input:
  ogg_page

-Output:
  n, is the version number (for current ogg, 0 is always returned,
     else error)

=cut
int
Ogg_LibOgg_ogg_page_version(og)
    int		og
  PREINIT:
    ogg_page *_og;
  CODE:
    _og = INT2PTR(ogg_page *, og);
    RETVAL = ogg_page_version(_og);
  OUTPUT:
    RETVAL

=head2 ogg_packet_clear

his function clears the memory used by the ogg_packet struct, but does not 
free the structure itself. Don't call it directly.
(http://www.xiph.org/ogg/doc/libogg/ogg_packet_clear.html)

-Input:
  ogg_packet

@Ouput:
  void

=cut
void
Ogg_LibOgg_ogg_packet_clear(op)
    int		op
  PREINIT:
    ogg_packet *_op;
  CODE:
    _op = INT2PTR(ogg_packet *, op);
    ## ogg_packet_clear(_op);



=head1 Functions (Encoding)

=cut

=head2 ogg_stream_packetin

This function submits a packet to the bitstream for page encapsulation. After this 
is called, more packets can be submitted, or pages can be written out.
(http://www.xiph.org/ogg/doc/libogg/ogg_stream_packetin.html)

-Input:
  ogg_stream_state
  ogg_packet

-Output:
   0, on success
  -1, on internal error

=cut
int 
Ogg_LibOgg_ogg_stream_packetin(os, op)
    int		os
    int 	op
  PREINIT:
    ogg_stream_state *_os;
    ogg_packet *_op;
  CODE:
    _os = INT2PTR(ogg_stream_state *, os);
    _op = INT2PTR(ogg_packet *, op);
    RETVAL = ogg_stream_packetin(_os, _op);
  OUTPUT:
    RETVAL


=head2 ogg_stream_pageout

This function forms packets into pages, this would be called after using ogg_stream_packetin().
(http://www.xiph.org/ogg/doc/libogg/ogg_stream_pageout.html)

-Input:
  ogg_stream_state
  ogg_page

-Output:
  0, insufficient data or internal error
  != 0, page has been completed and returned.

=cut
int
Ogg_LibOgg_ogg_stream_pageout(os, og)
    int 	os
    int		og
  PREINIT:
    ogg_stream_state *_os;
    ogg_page *_og;
  CODE:
    _os = INT2PTR(ogg_stream_state *, os);
    _og = INT2PTR(ogg_page *, og);
    RETVAL = ogg_stream_pageout(_os, _og);
  OUTPUT:
    RETVAL


=head2 ogg_stream_flush

This function checks for remaining packets inside the stream and forces remaining 
packets into a page, regardless of the size of the page.
(http://www.xiph.org/ogg/doc/libogg/ogg_stream_flush.html)

-Input:
  ogg_stream_state
  ogg_page

-Output:
  0, means that all packet data has already been flushed into pages
  != 0, means that remaining packets have successfully been flushed into the page.

=cut
int
Ogg_LibOgg_ogg_stream_flush(os, og)
    int		os
    int 	og
  PREINIT:
    ogg_stream_state *_os;
    ogg_page *_og;
  CODE:
    _os = INT2PTR(ogg_stream_state *, os);
    _og = INT2PTR(ogg_page *, og);
    RETVAL = ogg_stream_flush(_os, _og);
  OUTPUT:
    RETVAL
 


=head1 Functions (Decoding)

=cut


=head2 ogg_sync_init

ogg sync init, This function is used to initialize an ogg_sync_state 
struct to a known initial value in preparation for manipulation of an 
Ogg bitstream. (http://www.xiph.org/ogg/doc/libogg/ogg_sync_init.html)

-Input: 
  ogg_sync_state (memory addr)

-Output:
  0 (always)

=cut
int
Ogg_LibOgg_ogg_sync_init(oy)
    int		oy
  PREINIT:
    ogg_sync_state *_oy;
  CODE:
    _oy = INT2PTR(ogg_sync_state *, oy);    
    RETVAL = ogg_sync_init(_oy);
  OUTPUT:
    RETVAL  


=head2 ogg_sync_clear

This function is used to free the internal storage of an ogg_sync_state 
struct and resets the struct to the initial state.
(http://www.xiph.org/ogg/doc/libogg/ogg_sync_clear.html)

-Input:
  ogg_sync_state

-Output:
  0, always

=cut
int
Ogg_LibOgg_ogg_sync_clear(oy)
    int		oy
  PREINIT:
    ogg_sync_state *_oy;
  CODE:
    _oy = INT2PTR(ogg_sync_state *, oy);
    RETVAL = ogg_sync_clear(_oy);
  OUTPUT:
    RETVAL


=head2 ogg_sync_reset

This function is used to reset the internal counters of the ogg_sync_state struct 
to initial values. (http://www.xiph.org/ogg/doc/libogg/ogg_sync_reset.html)

-Input:
  ogg_sync_state

-Output:
  0, always

=cut
int
Ogg_LibOgg_ogg_sync_reset(oy)
    int		oy
  PREINIT:
    ogg_sync_state *_oy;
  CODE:
    _oy = INT2PTR(ogg_sync_state *, oy);
    RETVAL = ogg_sync_reset(_oy);
  OUTPUT:
    RETVAL
    

=head2 ogg_sync_destroy

This function is used to destroy an ogg_sync_state struct and free all memory used.
(http://www.xiph.org/ogg/doc/libogg/ogg_sync_destroy.html)

-Input:
  ogg_sync_state

@Ouput:
  0, always

=cut
int
Ogg_LibOgg_ogg_sync_destroy(oy)
    int		oy
  PREINIT:
    ogg_sync_state *_oy;
  CODE:
    _oy = INT2PTR(ogg_sync_state *, oy);
    RETVAL = ogg_sync_destroy(_oy);
  OUTPUT:
    RETVAL


=head2 ogg_sync_check

This function is used to check the error or readiness condition of an ogg_sync_state 
structure. (http://www.xiph.org/ogg/doc/libogg/ogg_sync_check.html)

-Input:
  ogg_sync_state

-Output:
  0, is returned if the ogg_sync_state structure is initialized and ready.
  != 0, if the structure was never initialized, or if an unrecoverable internal error

=cut
int
Ogg_LibOgg_ogg_sync_check(oy)
    int		oy
  PREINIT:
    ogg_sync_state *_oy;
  CODE:
    _oy = INT2PTR(ogg_sync_state *, oy);
    RETVAL = ogg_sync_check(_oy);
  OUTPUT:
    RETVAL


=head2 ogg_sync_buffer

This function is used to provide a properly-sized buffer for writing. 
(http://www.xiph.org/ogg/doc/libogg/ogg_sync_buffer.html)

-Input:
  ogg_sync_state
  size

-Output:
  Returns a pointer to the newly allocated buffer or NULL on error

=cut
void
Ogg_LibOgg_ogg_sync_buffer(oy, size);
    int		oy
    int		size
  PREINIT:
    ogg_sync_state *_oy;
    char *buffer;
  PPCODE:
    _oy = INT2PTR(ogg_sync_state *, oy);
    if((buffer = ogg_sync_buffer(_oy, size)) != NULL) {
      XPUSHs(sv_2mortal(newSViv(PTR2IV(buffer))));
    } else {
      XSRETURN_UNDEF;
    }

    
=head2 ogg_sync_wrote

This function is used to tell the ogg_sync_state struct how many bytes we 
wrote into the buffer. 
(http://www.xiph.org/ogg/doc/libogg/ogg_sync_wrote.html)

-Input:
  ogg_sync_state
  bytes

-Output:
  -1 if the number of bytes written overflows the internal storage of 
     the ogg_sync_state struct or an internal error occurred. 
   0 in all other cases.

=cut
int
Ogg_LibOgg_ogg_sync_wrote(oy, bytes)
    int		 oy
    long 	 bytes
  PREINIT:
    ogg_sync_state *_oy;
  CODE:
    _oy = INT2PTR(ogg_sync_state *, oy);
    RETVAL = ogg_sync_wrote(_oy, bytes);
  OUTPUT:
    RETVAL


=head2 ogg_sync_pageseek

This function synchronizes the ogg_sync_state struct to the next ogg_page. 
(http://www.xiph.org/ogg/doc/libogg/ogg_sync_pageseek.html)

-Input:
  ogg_sync_state
  ogg_page

-Output:
 -n means that we skipped n bytes within the bitstream.
  0 means that we need more data, or than an internal error occurred.
  n means that the page was synced at the current location, 
    with a page length of n bytes. 

=cut
int
Ogg_LibOgg_ogg_sync_pageseek(oy, og)
    int		oy
    int 	og
  PREINIT:
    ogg_sync_state *_oy;
    ogg_page *_og;
  CODE:
    _oy = INT2PTR(ogg_sync_state *, oy);
    _og = INT2PTR(ogg_page *, og);
    RETVAL = ogg_sync_pageseek(_oy, _og);
  OUTPUT:
    RETVAL


=head2 ogg_sync_pageout

This function takes the data stored in the buffer of the ogg_sync_state struct
and inserts them into an ogg_page. In an actual decoding loop, this function 
should be called first to ensure that the buffer is cleared. 
(http://www.xiph.org/ogg/doc/libogg/ogg_sync_pageout.html). 

-Input:
  ogg_sync_state
  ogg_page

-Output:
  -1 returned if stream has not yet captured sync (bytes were skipped).
   0 returned if more data needed or an internal error occurred.
   1 indicated a page was synced and returned.

=cut
int
Ogg_LibOgg_ogg_sync_pageout(oy, og);
    int		oy
    int		og
  PREINIT:
    ogg_sync_state *_oy;
    ogg_page *_og;
  CODE:
    _oy = INT2PTR(ogg_sync_state *, oy);
    _og = INT2PTR(ogg_page *, og);
    RETVAL = ogg_sync_pageout(_oy, _og); 
  OUTPUT:
    RETVAL


=head2 ogg_stream_pagein

This function adds a complete page to the bitstream. In a typical decoding situation, 
this function would be called after using ogg_sync_pageout to create a valid ogg_page 
struct. (http://www.xiph.org/ogg/doc/libogg/ogg_stream_pagein.html)

-Input:
  ogg_stream_state
  ogg_page

-Output:
  -1 indicates failure.
   0 means that the page was successfully submitted to the bitstream.

=cut
int
Ogg_LibOgg_ogg_stream_pagein(os, og)
    int		os
    int 	og
  PREINIT:
    ogg_stream_state *_os;
    ogg_page *_og;
  CODE:
    _os = INT2PTR(ogg_stream_state *, os);
    _og = INT2PTR(ogg_page *, og); 
    RETVAL = ogg_stream_pagein(_os, _og);
  OUTPUT:
    RETVAL


=head2 ogg_stream_packetout

This function assembles a data packet for output to the codec decoding engine. 
The data has already been submitted to the ogg_stream_state and broken into segments. 
Each successive call returns the next complete packet built from those segments.
(http://www.xiph.org/ogg/doc/libogg/ogg_stream_packetout.html)

-Input:
  ogg_stream_state
  ogg_packet

-Output:
  -1 if we are out of sync and there is a gap in the data.
   0 insufficient data available to complete a packet, or unrecoverable internal error occurred.
   1 if a packet was assembled normally. op contains the next packet from the stream.

=cut
int
Ogg_LibOgg_ogg_stream_packetout(os, op)
    int		os
    int		op
  PREINIT:
    ogg_stream_state *_os;
    ogg_packet *_op;
  CODE:
    _os = INT2PTR(ogg_stream_state *, os);
    _op = INT2PTR(ogg_packet *, op);
    RETVAL = ogg_stream_packetout(_os, _op);
  OUTPUT:
    RETVAL


=head2 ogg_stream_packetpeek

This function attempts to assemble a raw data packet and returns it without advancing 
decoding. (http://www.xiph.org/ogg/doc/libogg/ogg_stream_packetpeek.html)

-Input:
  ogg_stream_state
  ogg_packet

-Output:
  -1, no packet available due to lost sync or a hole in the data.
   0, insufficient data available to complete a packet, or on unrecoverable internal error
   1, packet is available

=cut
int
Ogg_LibOgg_ogg_stream_packetpeek(os, op)
    int 	os
    int 	op
  PREINIT:
    ogg_stream_state *_os;
    ogg_packet *_op;
  CODE:
    _os = INT2PTR(ogg_stream_state *, os);
    _op = INT2PTR(ogg_packet *, op);
    RETVAL = ogg_stream_packetpeek(_os, _op);
  OUTPUT:
    RETVAL


=head1 Functions (Miscellaneous)

Functions to manipulate C Structures

=cut

=head1 get_ogg_page

Gets the data contained in ogg_page and return as a hash reference.

-Input:
  ogg_page

-Output:
  hashref

=cut
HV *
Ogg_LibOgg_get_ogg_page(og)
    int		og
  PREINIT:
    ogg_page *_og;
  CODE:
    _og = INT2PTR(ogg_page *, og);
    RETVAL = newHV();
    sv_2mortal((SV*)RETVAL);	/* convert the hash inside the RETVAL to a mortal */
    hv_store(RETVAL, "header", strlen("header"), newSVpv((char *)_og->header, _og->header_len), 0);
    hv_store(RETVAL, "header_len", strlen("header_len"), newSViv(_og->header_len), 0);
    hv_store(RETVAL, "body", strlen("body"), newSVpv((char *)_og->body, _og->body_len), 0);
    hv_store(RETVAL, "body_len", strlen("body_len"), newSViv(_og->body_len), 0);
  OUTPUT:
    RETVAL


=head1 CAVEATS

B<ogg_page> and B<ogg_packet> structs mostly point to storage in libvorbis/libtheora. 
They're never freed or manipulated directly. You may get a malloc error doing so.

B<oggpack_buffer> struct which is used with libogg's bitpacking functions is not exposed, 
as you should never need to directly access anything in this structure. So are the
functions manipulating oggpack_buffer, they too are not exposed. 
(http://www.xiph.org/ogg/doc/libogg/oggpack_buffer.html)

B<ogg_stream_iovecin>, C<not implemented> as this function submits packet data (in the form of an 
array of ogg_iovec_t, rather than using an ogg_packet structure) to the bitstream for page 
encapsulation. (http://www.xiph.org/ogg/doc/libogg/ogg_stream_iovecin.html)

=cut


=head1 AUTHORS

Vigith Maurice <vigith@yahoo-inc.com> L<www.vigith.com>

=cut

=head1 COPYRIGHT

Vigith Maurice (C) 2011

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=cut
