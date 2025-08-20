                     THE HISTORY OF (Term::)ANSIEncode

This utility actually came from an abandoned project called "BBSUniversal".
It was a perl based modern BBS program that had various screen output formats
like ANSI, PETSCII and ATASCII.  It was a fully multithreaded application
that acted like a server for multiple network connections.  Locally, it
actually worked quite well.

However, it seemed every single Perl module for networking had piss-poor
telnet server implementations and configuring a socket for per-character
input never worked how I intended.

It accepted connections just fine, and sent various output standards just
fine, but getting single character input without blocking and the necessity
of a newline seemed frustratingly impossible.

I finally just gave up, especially after seeing the SBBS project written in C.
It was pretty much the same thing, but compiled.  So I ditched the
BBSUniversal project.

However, I had a tokenized markup language for ANSI, PETSCII and ATASCII and
decided why not incorporate the ANSI driver as a stand-alone utility?  So
this is the result of that idea.  (Term::)ANSIEncode is the result.

All code relating to sockets and networking were converted to simple "print"
statements.  This makes pipes etc, easy to do.

I use this utility myself for making colorful banners for various servers I
work with.

NOTE:  I actually fixed the network problem I mentioned above.  I may just
       finish the BBS program... eventually.
