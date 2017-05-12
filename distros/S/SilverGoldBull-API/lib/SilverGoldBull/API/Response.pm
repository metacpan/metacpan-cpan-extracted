package SilverGoldBull::API::Response;

use strict;
use warnings;

use Mouse;

has 'success' => (
  is => 'ro',
  isa => 'Maybe[Bool]',
  required => 1,
  reader => 'is_success',
);

has 'data' => (
  is  => 'ro',
  isa => 'Maybe[Any]',
  reader => 'data',
  required => 1,
);


1;