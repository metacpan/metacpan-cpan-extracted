#!/usr/local/bin/perl

use strict;
use warnings;

use Test::More;

use Solstice::State::FlowTransition;

plan(tests => 10);

my $transition = new Solstice::State::FlowTransition('action',
                                                     'application',
                                                     'name',
                                                     'backmessage',
                                                     {update => 1,
                                                      revert => 0,
                                                      freshen => 0,
                                                      commit => 1,
                                                      validate => 1});

ok($transition,
   "Creating transition object");

cmp_ok($transition->getName(), 'eq', 'action',
       "Getting transition action");

cmp_ok($transition->getApplicationName(), 'eq', 'application',
       "Getting application namespace");

cmp_ok($transition->getPageFlowName(), 'eq', 'name',
       "Getting pageflow name");

cmp_ok($transition->getBackErrorMessage(), 'eq', 'backmessage',
       "Getting back error lang key");

ok($transition->requiresUpdate(), "Requires update = 1");

ok(!$transition->requiresRevert(), "Requires revert = 0");

ok(!$transition->requiresFresh(), "Requires fresh = 0");

ok($transition->requiresCommit(), "Requires commit = 1");

ok($transition->requiresValidation(), "Requires validate = 1");

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
