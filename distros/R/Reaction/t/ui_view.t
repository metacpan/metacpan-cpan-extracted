use lib 't/lib';
use strict;
use warnings;

use Test::Class;
use RTest::UI::View;

Test::Class->runtests(
  RTest::UI::View->new,
);
