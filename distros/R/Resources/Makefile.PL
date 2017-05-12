# Copyright 1996 Francesco Callari, McGill University. See notice
# at end of this file.
#
# Filename: Makefile.PL
# Author: Francesco Callari (franco@cim.mcgill.ca)
# Created: Mon May 20 12:14:20 1996
# Version: $Id: Makefile.PL,v 1.1 1996/06/09 21:09:43 franco Exp franco $
#

$RCSID='$Id: Makefile.PL,v 1.1 1996/06/09 21:09:43 franco Exp franco $ ';

use ExtUtils::MakeMaker;

&WriteMakefile(
	       NAME     => "Resources",
	       DISTNAME => "Resources",
	       VERSION  => "1.04",
	       dist     => {COMPRESS => 'gzip', SUFFIX => 'gz'},
	       test     => {TEST_TYPE => '.test.pl'},
	      );


1;
__END__
# Local Variables:
# mode: perl
# End:

=head1 BUGS

=head1 AUTHOR

	Francesco Callari <franco@cim.mcgill.ca> 
	Artifical Perception Laboratory,
	Center for Intelligent Machines, 
	McGill University.

=head1 COPYRIGHT

Copyright 1996 Francesco Callari, McGill University

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose without fee is hereby granted without fee,
provided that the above copyright notice appear in all copies and that both
that copyright notice and this permission notice appear in supporting
documentation, and that the name of McGill not be used in advertising or
publicity pertaining to distribution of the software without specific,
written prior permission.  McGill makes no representations about the
suitability of this software for any purpose.  It is provided "as is"
without express or implied warranty.

MCGILL DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING ALL
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS.  IN NO EVENT SHALL
MCGILL BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY
DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

=cut
