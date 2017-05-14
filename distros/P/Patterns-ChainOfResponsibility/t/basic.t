use strict;
use warnings FATAL => 'all';
use Test::More tests => 4;

BEGIN {
  use_ok 'Patterns::ChainOfResponsibility::Application';
  use_ok 'Patterns::ChainOfResponsibility::Broadcast';
  use_ok 'Patterns::ChainOfResponsibility::Filter';
  use_ok 'Patterns::ChainOfResponsibility::Provider';
}

done_testing();
