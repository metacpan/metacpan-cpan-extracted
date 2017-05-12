use lib 't/lib';
use strict;
use warnings;

use Test::Class;

BEGIN { $ENV{DBIC_OVERWRITE_HELPER_METHODS_OK} = 1; }

use RTest::UI::ViewPort::ListView;

Test::Class->runtests(
  RTest::UI::ViewPort::ListView->new,
);
