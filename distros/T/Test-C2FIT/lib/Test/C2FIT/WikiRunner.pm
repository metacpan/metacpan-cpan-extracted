# $Id: WikiRunner.pm,v 1.7 2006/06/16 15:20:56 tonyb Exp $
#
# Copyright (c) 2002-2005 Cunningham & Cunningham, Inc.
# Released under the terms of the GNU General Public License version 2 or later.
#
# Perl translation by Dave W. Smith <dws@postcognitive.com>
# Modified by Tony Byrne <fit4perl@byrnehq.com>

package Test::C2FIT::WikiRunner;

use base 'Test::C2FIT::FileRunner';
use strict;

1;

__END__

=head1 NAME

Test::C2FIT::WikiRunner - a runner class operating on (wiki) html files. 

=head1 SYNOPSIS

	$runner = new Test::C2FIT::WikiRunner();
	$runner->run($infile,$outfile);


=head1 DESCRIPTION

Either you use this class as a starting point for your tests or your test documents refer to other test
documents which shall be processed recursively.

To run your tests, it might be even simplier to use C<WikiRunner.pl> or C<perl -MTest::C2FIT -e wiki_runner>.

In difference to Test::C2FIT::FileRunner, this class 
expects to find E<lt>wikiE<gt>, E<lt>tableE<gt>, E<lt>trE<gt> and E<lt>tdE<gt> in the input
document.


=head1 SEE ALSO

Extensive and up-to-date documentation on FIT can be found at:
http://fit.c2.com/

=cut
