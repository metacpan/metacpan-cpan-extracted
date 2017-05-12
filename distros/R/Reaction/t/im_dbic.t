use lib 't/lib';
use strict;
use warnings;

use Test::Class;
BEGIN { $ENV{DBIC_OVERWRITE_HELPER_METHODS_OK} = 1; }
use RTest::InterfaceModel::Reflector::DBIC;


Test::Class->runtests(
  RTest::InterfaceModel::Reflector::DBIC->new(),
);
