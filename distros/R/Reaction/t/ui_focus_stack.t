use lib 't/lib';
use strict;
use warnings;

use Test::Class;
use RTest::UI::FocusStack;

Test::Class->runtests(
  RTest::UI::FocusStack->new,
);

