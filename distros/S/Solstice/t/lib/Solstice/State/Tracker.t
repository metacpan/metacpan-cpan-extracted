#!/usr/local/bin/perl

use strict;
use warnings;

use Test::More;

use Solstice::State::Tracker;
use Solstice::State::Machine;
use Solstice::Configure;

plan(tests => 13);

my $config = new Solstice::Configure();
$config->setDevelopmentMode(0);
my $solsticeRoot = $config->getRoot();

Solstice::State::Machine->initialize(
  {TestApp => "$solsticeRoot/t/lib/Solstice/State/teststate.xml"});

my $tracker = new Solstice::State::Tracker('TestApp');

ok($tracker, "Creating state tracker");

$tracker->startApplication('TestApp::Main', 'TestApp::home');

cmp_ok($tracker->getState(), 'eq', 'TestApp::home',
       "Getting state");

ok(!$tracker->canUseBackButton('go_to_work'),
       "Can use back button?");

ok(!$tracker->requiresValidation('stay_home'),
   "Requires validation: false");

ok(!$tracker->requiresRevert('go_to_work'),
   "Requires revert: false");

ok(!$tracker->requiresFresh('go_to_work'),
   "Requires fresh: false");

ok(!$tracker->requiresCommit('go_to_work'),
   "Requires commit: false");

ok($tracker->requiresUpdate('go_to_work'),
   "Requires update: true");

my $state = $tracker->transition('go_to_work');

cmp_ok($tracker->getBackErrorMessage(), 'eq', 'nope',
       "Getting back error lang key");

cmp_ok($state, 'eq', 'TestApp::work',
       "Transitioning");

cmp_ok($tracker->getState(), 'eq', "TestApp::work",
       "Getting current state");

$tracker->failRevert();

cmp_ok($tracker->getState(), 'eq', 'TestApp::school',
       "Failing over to fail state");

$tracker->transition('go_home');

cmp_ok($tracker->getBackErrorMessage(), 'eq', 'nope',
      "Getting back error lang key after another transition");

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
