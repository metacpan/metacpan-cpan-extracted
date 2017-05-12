#!/usr/local/bin/perl

use strict;
use warnings;

use Test::More;

use Solstice::State::Machine;
use Solstice::Configure;

plan(tests => 19);

my $config = Solstice::Configure->new();
$config->setDevelopmentMode(0);
my $solsticeRoot = $config->getRoot();

Solstice::State::Machine->initialize(
  {TestApp => "$solsticeRoot/t/lib/Solstice/State/teststate.xml"});

my $machine;

ok($machine = new Solstice::State::Machine(),
   "Creating new machine");

cmp_ok($machine->getStartState('TestApp'), "eq", "TestApp::home",
       "Getting start state");

my ($doPop, $newFlow, $newState) =
  $machine->transition($machine->getMainFlow('TestApp'),
                       "TestApp::home",
                       "go_to_work");

cmp_ok($doPop, '==', 0, "Testing transition flow pop");
ok(!$newFlow, "No new flow");
cmp_ok($newState, 'eq', "TestApp::work", "Transitioning to new state");

($doPop, $newFlow, $newState) =
  $machine->transition($machine->getMainFlow('TestApp'),
                       "TestApp::home",
                       "add_workplace");

cmp_ok($doPop, '==', 0, "Testing transition flow pop");
ok($newFlow, "Transition to new flow");
cmp_ok($newState, 'eq', "TestApp::add_workplace",
       "Transition to flow entrance");

($doPop, $newFlow, $newState) = $machine->transition($newFlow,
                                                     "TestApp::add_workplace",
                                                     "done");

cmp_ok($doPop, '==', 1, "Testing transition flow pop");

ok(!$machine->canUseBackButton($machine->getMainFlow('TestApp'),
                               "TestApp::home",
                               "go_to_work"),
   "Testing back button disabling");

ok($machine->canUseBackButton($machine->getMainFlow('TestApp'),
                               "TestApp::home",
                               "go_to_school"),
   "Testing back button disabling");

cmp_ok($machine->getBackErrorMessage($machine->getMainFlow('TestApp'),
                                     "TestApp::home",
                                     "go_to_work"),
       "eq",
       "nope",
       "Testing back button error message");

ok(!$machine->requiresValidation($machine->getMainFlow('TestApp'),
                                 $machine->getStartState('TestApp'),
                                 "go_to_work"),
   "Validate = false");

ok(!$machine->requiresRevert($machine->getMainFlow('TestApp'),
                             $machine->getStartState('TestApp'),
                             "go_to_work"),
   "Revert = false");

ok(!$machine->requiresFresh($machine->getMainFlow('TestApp'),
                            $machine->getStartState('TestApp'),
                            "go_to_work"),
   "Freshen = false");

ok(!$machine->requiresCommit($machine->getMainFlow('TestApp'),
                             $machine->getStartState('TestApp'),
                             "go_to_work"),
   "Commit = false");

ok($machine->requiresUpdate($machine->getMainFlow('TestApp'),
                            $machine->getStartState('TestApp'),
                            "go_to_work"),
   "Update = true");

cmp_ok($machine->getControllerName("TestApp::school"),
       "eq",
       'Solstice::Controller',
       "Getting a controller");

cmp_ok($machine->getRevertFailoverState($machine->getMainFlow('TestApp'),
                                        "TestApp::work"),
       "eq",
       "TestApp::school",
       "Failing over to revert");

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
