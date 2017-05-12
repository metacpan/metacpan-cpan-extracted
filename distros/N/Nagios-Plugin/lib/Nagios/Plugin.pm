package Nagios::Plugin;

use strict;
use warnings;

our $VERSION = '0.990001';

die "This doesn't even have a proper Makefile.PL, how did you install it?\n";

0; # This is the end, my only friend, the end.

=head1 NAME

Nagios::Plugin - Removed from CPAN by request of Nagios Enterprises, succeeded
by Monitoring::Plugin

=head1 EXPLANATION

Due to disagreements between the original authors of L<Nagios::Plugin> and
Nagios Enterprises, the authors of L<Nagios::Plugin> left the Nagios
Enterprises controlled Nagios Plugins Development Team and have continued
development in the L<Monitoring::Plugin> namespace - see also the new website
at http://monitoring-plugins.org/

Nagios Inc. characterise the disagreement as being that the team "kept
advertising other products"; the original authors characterise it as thinking
that putting a list of nagios plugin compatible software on the site was a
good way to encourage the community and demonstrate that nagios is the gold
standard. I originally left this off since I felt it only made them look
foolish, but according to Nagios employee Mike O'Keefe they "find that truth
stands the test of time", and also informed me that if I'm going to make public
statements "please be sure to make them accurately, as not doing so could
be construed as defamation of character", so I have done as requested.

The original code was left on CPAN with a deprecation notice attached but
we were contacted by Nagios employee Scott Wilkerson who, I presume due to
misunderstanding the nature of PAUSE permissions, called the package "hijacked"
- however, given his opening sentence was "To whom it may concern & CPAN Legal
Team", a decision was made to remove that version of the distribution anyway
in order to avoid any risk of legal action against the volunteers maintaining
PAUSE and the CPAN infrastructure. 

Mike informs me that "Simply copying legal on an email should not be construed
as a threat of legal action", and that instead the mention of legal was because
"We find it easier to get them involved from the start as they tend to
understand the gravity of the situation a little quicker than most folks." The
difference, if any, between this and an implied legal threat is left as an
exercise to the reader; I'm a programmer, not a lawyer, and as such am not
qualified to have an opinion thereupon.

Although the Nagios Plugins Development Team required a CLA assigning
copyright of the code to Nagios Enterprises, the PAUSE permissions remain
with the original authors of the code, and so Nagios Enterprises' version
is now available in the L<Nagios::Monitoring::Plugin> namespace. This
information was kindly provided to me by Mike since Scott had chosen to
stop responding to my emails six months before my first tombstone release.

This tombstone release is made by me, as a CPAN uploader, and not as an
official statement from the PAUSE administration - no PAUSE superpowers have
been involved in the uploading, merely a co-maint grant by the original authors
of the module on the grounds of "we're sick of Nagios Enterprises related
drama and would like it to go away".

I have invited both Scott and Mike to propose alternative text if they feel
that this release doesn't accurately reflect their side of the situation, but
Scott stopped talking to me and Mike outright refused; if anybody is aware
of remaining factual inaccuracies, please don't hesitate to drop me an email.

=head1 AUTHOR

This tombstone release was written by:

Matt S Trout (IRC:mst) (cpan:MSTROUT) <mst@shadowcat.co.uk>

=head1 COPYRIGHT

Copyright (c) 2015 Matt S Trout.

This not-a-library is free software and may be distributed under the same terms
as perl5 itself, or at your option any other Free Software license as declared
so by the Free Software Foundation.

Honestly, I'd've put it in the public domain but the idea of somebody
restributing it under the WTFPL amuses me too much.

=cut
