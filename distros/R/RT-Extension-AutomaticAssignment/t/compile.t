use strict;
use warnings;

use RT::Extension::AutomaticAssignment::Test tests => undef;

use_ok('RT::Extension::AutomaticAssignment');

use_ok('RT::Action::AutomaticAssignment');
use_ok('RT::Action::AutomaticReassignment');

use_ok('RT::Extension::AutomaticAssignment::Chooser');
use_ok('RT::Extension::AutomaticAssignment::Chooser::ActiveTickets');
use_ok('RT::Extension::AutomaticAssignment::Chooser::Random');
use_ok('RT::Extension::AutomaticAssignment::Chooser::RoundRobin');
use_ok('RT::Extension::AutomaticAssignment::Chooser::TimeLeft');

use_ok('RT::Extension::AutomaticAssignment::Filter');
use_ok('RT::Extension::AutomaticAssignment::Filter::ExcludedDates');
use_ok('RT::Extension::AutomaticAssignment::Filter::MemberOfGroup');
use_ok('RT::Extension::AutomaticAssignment::Filter::MemberOfRole');
use_ok('RT::Extension::AutomaticAssignment::Filter::WorkSchedule');

use_ok('RT::CustomFieldValues::ServiceBusinessHours');

done_testing;
