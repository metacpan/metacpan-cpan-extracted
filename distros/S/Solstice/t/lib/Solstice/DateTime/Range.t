#!/usr/local/bin/perl


use strict;
use warnings;

use constant TRUE  => 1;
use constant FALSE => undef;

use Test::More;

plan(tests => 31);

use Solstice::DateTime::Range;
use Solstice::DateTime;

my $datetime0 = new Solstice::DateTime("2000-01-01 12:00:00"); 
my $datetime1 = new Solstice::DateTime("2005-06-21 12:47:34");
my $datetime2 = new Solstice::DateTime("1983-08-24 07:03:00");
my $datetime3 = new Solstice::DateTime("2010-06-23 23:56:29");
my $datetime4 = new Solstice::DateTime("2003-09-10 17:33:34");
my $datetime5 = new Solstice::DateTime("12/10/05");
my $datetime6 = new Solstice::DateTime("2005-06-21 12:47:34");

# testing with a valid range, initialized with valid datetimes
ok (my $range0 = new Solstice::DateTime::Range($datetime0, $datetime1), "initializing range0");
ok ($range0->isValidRange(), "checking if range0 is valid range");
ok ($range0->isDateTimeBeforeRange($datetime2), "checking if datetime2 is before range0");
is ($range0->isDateTimeBeforeRange($datetime3), 0, "checking that datetime3 is NOT before range0");
is ($range0->isDateTimeBeforeRange($datetime4), 0, "checking that datetime4 is NOT before range0");
ok ($range0->isDateTimeAfterRange($datetime3), "checking that datetime3 is after range0");
is ($range0->isDateTimeAfterRange($datetime2), 0, "checking that datetime2 is NOT after range0");
is ($range0->isDateTimeAfterRange($datetime4), 0, "checking that datetime4 is NOT after range0");
ok ($range0->isDateTimeInRange($datetime4), "checking that datetime4 is in range0");
is ($range0->isDateTimeInRange($datetime2), 0, "checking that datetime2 is NOT in range0");
is ($range0->isDateTimeInRange($datetime3), 0, "checking that datetime3 is NOT in range0");
is ($range0->isNowInRange(), 0, "checking that now is NOT in range0");
ok ($range0->getIntervalString(), "getting interval string");

# testing with a valid range, initialized as empty 
ok (my $range1 = new Solstice::DateTime::Range(), "initializing an empty range");
is ($range1->isValidRange(), 0, "checking that range1 is NOT valid");
is ($range1->isDateTimeAfterRange($datetime0), undef, "isDateTimeAfterRange shouldn't work for range1");
ok ($range1->setStartDateTime($datetime1), "setting start datetime for range1");
is ($range1->isValidRange(), 0, "checking that range1 is still NOT valid");
is ($range1->isNowInRange(), undef, "isNowInRange shouldn't work for range1");
ok ($range1->setEndDateTime($datetime3), "setting end datetime for range1");
ok ($range1->isValidRange(), "checking that range1 is valid");
is ($range1->getIntervalString(), "1828 days, 11 hours, 8 minutes, 55 seconds", "checking getIntervalString");
is ($range1->getIntervalString(my $years = 1), "5 years, 2 days, 11 hours, 8 minutes, 55 seconds", "checking getIntervalString, with years");

# testing with an invalid range (the start date is after end date)
ok (my $range2 = new Solstice::DateTime::Range($datetime1, $datetime0), "initializing a bad range");
is ($range2->isValidRange(), 0, "ensure that range2 is NOT valid");
is ($range2->isDateTimeBeforeRange($datetime2), undef, "isDateTimeBeforeRange should return undef");

# testing with an invalid range (one of the dates is invalid)
ok (my $range3 = new Solstice::DateTime::Range($datetime0, $datetime5), "initializing another bad range");
is ($range3->isValidRange(),0, "make sure range3 is NOT valid");

# testing a range with identical endpoints
ok (my $range4 = new Solstice::DateTime::Range($datetime1, $datetime6), "initializing a range with identical endpoints");
is ($range4->isValidRange(),1, "make sure range4 is valid");
is ($range4->isDateTimeInRange($datetime6), 1, "checking that datetime6 is in range4");


exit 0;


=head1 COPYRIGHT

Copyright  1998-2006 Office of Learning Technologies, University of Washington

Licensed under the Educational Community License, Version 1.0 (the "License");
you may not use this file except in compliance with the License. You may obtain
a copy of the License at: http://www.opensource.org/licenses/ecl1.php

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

=cut
