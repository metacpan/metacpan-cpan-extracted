This module works also under Win32 ,it does not require
any ather packeges,is much simplier for use and instalation.(after
it will be released) .It will *not* force user to learn complicated
object relations and behavior ,as the bioperl project,in case he
wants to do as simple things as- getting DNA data from the
web,parsing it ,searching desirable chunk and (maybe in future)
running standart biological algoritms on it.
It will be able to download realy big files from NCBI ,such as contigs - 
not causing server error on the site.
The module also can be use with proxes.


The documentation is not ready sorry.
The module currently is a beta version but it already contain most of the functionality
I am planning for connecting to NCBI and formatting.

To install just run perl Makefile.pl

TODO:
Actualy it should be splitted to two different modules:
[1] The NCBI(SABio::NCBI) that will connect to the NCBI site.
[2] The Fasta(probably SABio::Fasta) for forrmatting and unformatting fasta documents.
