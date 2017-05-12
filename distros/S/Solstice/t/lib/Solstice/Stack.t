#!/usr/local/bin/perl

use strict;
use warnings;

use constant TRUE  => 1;
use constant FALSE => 0;

use Solstice::Stack;
use Test::More;

plan(tests => 17);

my $stack = Solstice::Stack->new();

### Tests to check normal functionality ###

ok ($stack->isEmpty(), "stack is initially empty");

ok (!$stack->top(), "top() initially returns undef");

ok ($stack->push("my"), "pushing element 'my' onto stack");
ok ($stack->push("first"), "pushing element 'first' onto stack");
ok ($stack->push("test"), "pushing element 'test' onto stack");

ok (!$stack->isEmpty(), "stack is not empty");

ok ($stack->top() eq 'test', "top returns correct element 'test'");

ok ($stack->pop() eq 'test', "popping element 'test' off of stack");

ok ($stack->top() eq 'first', "top returns correct element 'first'");

ok ($stack->pop() eq 'first', "popping element 'first' off of stack");

ok ($stack->top() eq 'my', "top returns correct element 'my'");

ok ($stack->pop() eq 'my', "popping element 'my' off of stack");

ok ($stack->isEmpty(), "stack is empty");

ok ($stack->push("my"), "pushing element 'my' onto stack");

ok (!$stack->isEmpty(), "stack is not empty");

ok ($stack->clear(), "clearing stack");

ok ($stack->isEmpty(), "stack is empty");


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
