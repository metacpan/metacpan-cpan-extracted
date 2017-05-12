# Little helper utility to generated the pod for the DTD from the TestNS.pm
# source code

# Asumes the DTD is stored as $TESNS_DTD and has a rather "loose" way
# to determine the begin and the end of the string.
# Start:    if (s/\$TESTNS_DTD=\'//){
# End: 	    if (s/\'\;//){

use strict;

open (FH, "TestNS.pm")|| die "could not open TestNS.pm";


print <<HEADER1;



\$VERSION="0";


=head1 NAME

Net::DNS::TestNS::DTD - DTD for the TestNS configurationf file

=head1 SYNOPSIS

Documentation only.
  
=head1 ABSTRACT

L<Net::DNS::TestNS> is configured throught he use of an XML documentation
file. The Document Type Definition is described below.


=cut

HEADER1

print "=head1 DESCRIPTION\n";


DOCLOOP: while (<FH>) {
    if (s/\$TESTNS_DTD=\'//){
	print $_;
	while (<FH>){
	    if (s/\'\;//){
		print $_;
		last DOCLOOP;
	    }else{
		print $_;
	    }
	}
    }
}


print <<FOOTER;

=head1 AUTHOR

Olaf Kolkman, E<lt>olaf\@net-dns.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2003-2005  RIPE NCC.  Author Olaf M. Kolkman  <olaf\@net-dns.net>

All Rights Reserved

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted,
provided that the above copyright notice appear in all copies and that
both that copyright notice and this permission notice appear in
supporting documentation, and that the name of the author not be
used in advertising or publicity pertaining to distribution of the
software without specific, written prior permission.


THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING
ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS; IN NO EVENT SHALL
AUTHOR BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY
DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.


=cut

FOOTER

1;
