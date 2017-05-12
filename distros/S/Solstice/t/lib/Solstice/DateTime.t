#!/usr/local/bin/perl

use strict;
use warnings;

use constant TRUE  => 1;
use constant FALSE => undef;

use Test::More;

plan(tests => 112);

use Solstice::DateTime;


ok (my $datetime0 = new Solstice::DateTime("2005-06-21 12:47:34"), "initializing date with MySQL format");
ok ($datetime0->isValid(), "checking validity of datetime0");
ok ($datetime0->isValidDate(), "checking validity of date in datetime0");
ok ($datetime0->isValidTime(), "checking validity of time in datetime0");
is ($datetime0->getYear(), 2005, "getting year from datetime0");
is ($datetime0->getMonth(), 6, "getting month from datetime0");
is ($datetime0->getDay(), 21, "getting day from datetime0");
is ($datetime0->getHour(), 12, "getting hour from datetime0");
is ($datetime0->getMin(), 47, "getting min from datetime0");
is ($datetime0->getSec(), 34, "getting sec from datetime0");
ok ($datetime0->addYears(5), "adding 5 years to datetime0");
is ($datetime0->getYear(), 2010, "getting updated year from datetime0");
ok ($datetime0->addMonths(1), "adding a month to datetime0");
is ($datetime0->getMonth(), 07, "getting updated month from datetime0");
ok ($datetime0->addDays(3), "adding 3 days to datetime0");
is ($datetime0->getDay(), 24, "getting updated day from datetime0");
ok ($datetime0->addHours(-6), "adding -6 hours to datetime0");
is ($datetime0->getHour(), 6, "getting updated hour from datetime0");
ok ($datetime0->addMinutes(4), "adding 4 minutes to datetime0");
is ($datetime0->getMin(), 51, "getting updated minutes from datetime0");
ok ($datetime0->addSeconds(5), "adding 5 days to datetime0");
is ($datetime0->getSec(), 39, "getting updated seconds from datetime0");

ok (my $datetime1 = new Solstice::DateTime("3984754"), "initializing date with unix format");
ok ($datetime1->isValid(), "checking validity of datetime1");
ok ($datetime1->isValidDate(), "checking validity of date in datetime1");
ok ($datetime1->isValidTime(), "checking validity of time in datetime1");

my $datehash = { year => 1983, 
    month => 8, 
    day => 24,
    hour => 7,
    min => 3,
    sec => 0,
    ampm => "am"
};
ok (my $datetime2 = new Solstice::DateTime($datehash), "initializing date with hash");
ok ($datetime2->isValid(), "checking validity of datetime2");
ok ($datetime2->isValidDate(), "checking validity of date in datetime2");
ok ($datetime2->isValidTime(), "checking validity of time in datetime2");
is ($datetime2->getYear(), 1983, "getting year from datetime2");
is ($datetime2->getMonth(), 8, "getting month from datetime2");
is ($datetime2->getDay(), 24, "getting day from datetime2");
is ($datetime2->getHour(), 7, "getting hour from datetime2");
is ($datetime2->getMin(), 3, "getting min from datetime2");
is ($datetime2->getSec(), 0, "getting sec from datetime2");
ok ($datetime2->setYear(1984), "setting year for datetime2");
is ($datetime2->getYear(), 1984, "getting updated year from datetime2");
ok ($datetime2->setMonth(12), "setting month for datetime2");
is ($datetime2->getMonth(), 12, "getting updated month from datetime2");
ok ($datetime2->setDay(5), "setting day for datetime2");
is ($datetime2->getDay(), 5, "getting updated day from datetime2");
ok ($datetime2->setHour(6), "setting hour for datetime2");
is ($datetime2->getHour(), 6, "getting updated hour from datetime2");
ok ($datetime2->setMin(34), "setting min for datetime2");
is ($datetime2->getMin(), 34, "getting min for datetime2");
ok ($datetime2->setSec(23), "setting sec for datetime2");
is ($datetime2->getSec(), 23, "getting sec for datetime2");

ok (my $datetime3 = new Solstice::DateTime("19991231235959"), "initializing date with ISO 8601 format");
ok ($datetime3->isValid(), "checking validity of datetime3");
ok ($datetime3->isValidDate(), "checking validity of date in datetime3");
ok ($datetime3->isValidTime(), "checking validity of time in datetime3");
is ($datetime3->getYear(), 1999, "getting year from datetime3");
is ($datetime3->getMonth(), 12, "getting month from datetime3");
is ($datetime3->getDay(), 31, "getting day from datetime3"); 
is ($datetime3->getHour(), 23, "getting hour from datetime3");
is ($datetime3->getMin(), 59, "getting min from datetime3");
is ($datetime3->getSec(), 59, "getting sec from datetime3");
ok ($datetime3->addDays(1), "adding 1 days to datetime3");
is ($datetime3->getYear(), 2000, "checking that the year changed to 2000 for datetime3");
is ($datetime3->getMonth(), 1, "checking that the month changed to 1 for datetime3");
is ($datetime3->getDay(), 1, "checking that the month changed to 1 for datetime3");

ok (my $datetime4 = new Solstice::DateTime('now'), "initializing date with current time");
is ($datetime4->isValid(), 1, "checking validity of datetime4");
is ($datetime4->isEmpty(), 0, "checking empty of datetime4");
is ($datetime4->isEqualTo($datetime3), 0, "checking datetime4 is not equal to datetime3");
is ($datetime4->isBefore(new Solstice::DateTime('now')), "0", "checking if datetime4 is before current time");
ok ($datetime4->toMovingWindow(), "output datetime4 as moving window");

ok (my $datetime5 = new Solstice::DateTime("1/1/2000 12:00:00"), "initializing date with form input format");

is ($datetime5->isValid(), 1, "checking validity of datetime5");
is ($datetime5->isValidDate(), 1, "checking validity of date in datetime5");
is ($datetime5->isValidTime(), 1, "checking validity of time in datetime5");
is ($datetime5->getYear(), 2000, "getting year from datetime5");
is ($datetime5->getMonth(), 1, "getting month from datetime5");
is ($datetime5->getDay(), 1, "getting day from datetime5");
is ($datetime5->getHour, 12, "getting hour from datetime5");
is ($datetime5->getMin, "00", "getting min from datetime5");
is ($datetime5->getSec, 0, "getting sec from datetime5");
$datetime5->setMonth(14); #setting illegal value
is ($datetime5->getYear(), 2000, "checking that year is unchanged for datetime5");
TODO: {
          local $TODO = "We don't check input yet, because it would break webq.
              We need to migrate to persistence values everywhere before we can 
              reject invalid dates";
          is ($datetime5->getMonth(), 1, "checking that illegal value was not accepted for datetime5");
      }
is ($datetime5->getDay(), 1, "checking that day is unchanged for datetime5");
is ($datetime5->isValid(), 0, "checking that datetime5 is no longer valid"); 

ok (my $datetime6 = new Solstice::DateTime("1/25"), "initializing a bad date");
isnt ($datetime6->isValid(), 1, "checking validity of datetime6");
isnt ($datetime6->isValidDate(), 1, "checking validity of date in datetime6");
isnt ($datetime6->isValidTime(), 1, "checking validity of time in datetime6");
is ($datetime6->isEmpty(), 1, "invalid date datetime6 is empty");
is ($datetime6->isBefore($datetime5), undef, "cannot compare invalid date datetime6 with another datetime");
is ($datetime6->toUnix(), undef, "cannot output invalid date datetime6");

ok (my $datetime61 = new Solstice::DateTime("08/44/2005 2:20:00"), "initializing a bad date");
isnt ($datetime61->isValid(), 1, "checking validity of datetime61");
is ($datetime61->isEmpty(), 0, "invalid date datetime61 is not empty");
is ($datetime61->toCommon(), undef, "cannot output invalid date datetime61");

is ($datetime3->isBefore($datetime5), undef, "checking that datetime3(valid) is not before datetime5(invalid)");
ok ($datetime3->isBefore($datetime0), "checking that datetime3 is before datetime0");
ok ($datetime3->isBeforeNow(), "checking that datetime3 is before now");
#warn $datetime5->isBefore($datetime3);
ok(!$datetime5->isBefore($datetime3), "checking that datetime5 is NOT before datetime3");
is ($datetime0->isBeforeNow(), 0, "checking that datetime0 is NOT before now");
is ($datetime3->isBefore($datetime3), 0, "datetime3 is not before itself");
my $datetime7 = new Solstice::DateTime("08/19/2005 2:20:00");
my $datetime8 = new Solstice::DateTime("08/19/2005 3:11:00");
is ($datetime7->isBefore($datetime8), 1, "08/19/2005 2:20:00 is before 08/19/2005 3:11:00");
is ($datetime8->isBefore($datetime7), 0, "08/19/2005 3:11:00 is not before 08/19/2005 2:20:00");


my $datetime = new Solstice::DateTime("08/19/2005 17:00:00");
is (my $sqldate = $datetime->toSQL(), "2005-08-19 17:00:00", "output date in SQL format");
is (my $isodate = $datetime->toISO(), "20050819170000", "output date in ISO 8601 format");
is (my $catdate = $datetime->toCommon(), "8/19/2005  5:00 PM", "output date in Common format");
ok ($datetime->toMovingWindow(), "output date as moving window");
ok ($datetime->toUnix(), "output date in Unix format");
is (my $customdate = $datetime->toString("%L/%d/%y"), "8/19/05", "output date in custom format");

my $datetime_clone = $datetime->clone();
ok ($datetime_clone->toUnix() == $datetime->toUnix(), "clone equals source");
ok ($datetime_clone->getIsNow() == $datetime->getIsNow(), "clone is_now equals source is_now");


my $compdate_1 = Solstice::DateTime->new('2007-01-01 00:00:00');
my $compdate_2 = Solstice::DateTime->new('2007-01-01 00:00:01');
my $compdate_3 = Solstice::DateTime->new('2007-01-01 00:00:01');

is ($compdate_1->cmpDate($compdate_2), -1, "cmpDate works lessthan");
is ($compdate_2->cmpDate($compdate_3), 0, "cmpDate works equal");
is ($compdate_3->cmpDate($compdate_1), 1, "cmpDate works greaterthan");

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
