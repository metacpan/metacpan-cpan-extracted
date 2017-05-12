#!/usr/local/bin/perl

use strict;
use warnings;

use Test::More;

use Solstice::State::PageFlow;
use Solstice::State::Transition;

plan(tests => 6);

my $pageflow = new Solstice::State::PageFlow('appname',
                                             'flowname',
                                             'entrance');

ok($pageflow, "Creating page flow");

$pageflow->addFailover('start', 'update', 'fail');

cmp_ok($pageflow->getFailover('start', 'update'), 'eq', 'fail',
       "Getting failover");

cmp_ok($pageflow->getName(), 'eq', 'flowname',
       "Getting page flow name");

cmp_ok($pageflow->getApplicationName(), 'eq', 'appname',
       "Getting applicatio namespace");

cmp_ok($pageflow->getEntrance(), 'eq', 'entrance',
       "Getting entrance state");

my $transition = new Solstice::State::Transition('action',
                                                 'targetstate',
                                                 'backmessage',
                                                 undef,
                                                 {update => 1,
                                                  revert => 0,
                                                  freshen => 0,
                                                  commit => 1,
                                                  validate => 1});

$pageflow->addTransition('start', $transition);

cmp_ok($pageflow->getTransition('start', 'action'), '==', $transition,
      "Getting transition");

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
