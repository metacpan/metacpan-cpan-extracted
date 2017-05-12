#!/usr/bin/perl -w
# -*- Mode: perl -*-
#======================================================================
#
# This package is free software and is provided "as is" without
# express or implied warranty.  It may be used, redistributed and/or
# modified under the same terms as perl itself. ( Either the Artistic
# License or the GPL. )
#
# $Id: ICal.pm,v 1.12 2001/08/04 05:53:12 srl Exp $
#
# (C) COPYRIGHT 2000-2001, Reefknot developers.
#
# See the AUTHORS file included in the distribution for a full list.
#======================================================================

use Net::ICal::Alarm;     
use Net::ICal::Attendee;
use Net::ICal::Calendar;
use Net::ICal::Component;
use Net::ICal::Duration;
use Net::ICal::ETJ;
use Net::ICal::Event;
use Net::ICal::Freebusy;
use Net::ICal::Journal;
use Net::ICal::Period;
use Net::ICal::Property;
use Net::ICal::Recurrence;
use Net::ICal::Time;     
use Net::ICal::Todo;
use Net::ICal::Trigger;
use Net::ICal::Util;

$VERSION = "0.15";

package Net::ICal;

1;

__END__


=head1 NAME

Net::ICal -- Interface to RFC2445 (iCalendar) calendaring
and scheduling protocol.

=head1 SYNOPSIS

  use Net::ICal;

=head1 DESCRIPTION

Net::ICal is a collection of Perl modules for manipulating iCalendar
(RFC2445) calendar data.

As of the 0.15 release, most of the functionality you want to 
find out about is in L<Net::ICal::Calendar>. See its manpages for
more details. 

This is ALPHA QUALITY SOFTWARE; it is under active development and
is not fully functional. For more information, see 
http://reefknot.sourceforge.net. 

=head1 METHODS

None for now; see L<Net::ICal::Calendar>.

=head1 SEE ALSO

First, look at the files in the examples/ directory of the distribution
to see some ways of using Net::ICal. 

The following modules make up the bulk of the functionality of
Net::ICal.  You should read their individual perldoc to see how they
work.

=over 4

=item *

Net::ICal::Alarm

=item *

Net::ICal::Attendee

=item *

Net::ICal::Calendar

=item *

Net::ICal::Component

=item *

Net::ICal::Duration

=item *

Net::ICal::ETJ

=item *

Net::ICal::Event

=item *

Net::ICal::Freebusy

=item *

Net::ICal::Journal

=item *

Net::ICal::Period

=item *

Net::ICal::Property

=item *

Net::ICal::Recurrence

=item *

Net::ICal::Time

=item *

Net::ICal::Timezone (with N::I::Standard and N::I::Daylight)

=item *

Net::ICal::Todo

=item *

Net::ICal::Trigger

=back

=begin testing

# test that this module can be loaded okay
BEGIN { use_ok( 'Net::ICal' ); }

=end testing
