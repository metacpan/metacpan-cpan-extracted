#!/usr/local/bin/perl -w

# -*- Mode: perl -*-
#======================================================================
#
# This package is free software and is provided "as is" without express
# or implied warranty.  It may be used, redistributed and/or modified
# under the same terms as perl itself. ( Either the Artistic License or the
# GPL. )
#
# $Id: test_journal.pl,v 1.1 2001/07/19 03:31:14 srl Exp $
#
# (C) COPYRIGHT 2000-2001, Reefknot developers.
# 
# See the AUTHORS file included in the distribution for a full list. 
#======================================================================


use lib '../lib';

use Net::ICal;

# Sample file to test proper functioning of Net::ICal::Journal. 

my $waiter = new Net::ICal::Attendee('monty@sillywalks.python.org');

my $journal = new Net::ICal::Journal (
                  organizer => $waiter,
                  summary => 'Grocery usage this week',
                 description => {content =>
'This week, we used 9 cans of Spam, 1 pound of bacon, 2 cans of baked beans, and 6 eggs. We also used 10 pounds of lettuce, 2 pounds of tomatoes, and 3L of white wine.'},
                                 ) ||
  die "Didn't get a valid ICal object";

my $cal = new Net::ICal::Calendar(journals => [$journal]);
print "\n" . $cal->as_ical;


print "\nPaste in the output from the script above (or any VCALENDAR with (an)\n"
    . "embedded VJOURNAL(s)). Hit Ctrl-D twice to end your input.\n\n";

undef $/; # slurp mode
$a = Net::ICal::Component->new_from_ical (<STDIN>);

print "\nBelow should be the same (except the order) as what you pasted:\n\n",
$a->as_ical;

