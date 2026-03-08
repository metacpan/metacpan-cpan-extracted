![ANSIEncode Logo](images/ANSI-Encode.png?raw=true "ANSIEncode Logo Title Text 1")

# THE HISTORY OF Term::ANSIEncode

This utility actually came from a project called "BBSUniversal".  It was a perl based modern BBS program that had various screen output formats like ANSI, PETSCII and ATASCII.  It was a fully multithreaded application that acted like a server for multiple network connections.

It had a tokenized markup language for ANSI, PETSCII and ATASCII and decided why not incorporate the ANSI driver as a stand-alone utility?  So this is the result of that idea.  Term::ANSIEncode is the result.

All code relating to sockets and networking were converted to simple "print" statements.  This makes pipes etc, easy to do.

I use this utility myself for making colorful banners for various servers I work with.
