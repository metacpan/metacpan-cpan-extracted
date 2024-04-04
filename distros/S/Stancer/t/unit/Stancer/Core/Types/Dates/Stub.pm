package Stancer::Core::Types::Dates::Stub;

use 5.020;
use strict;
use warnings;

use Moo;
use namespace::clean;

use Stancer::Core::Types::Dates qw(:all);

has a_month => (
    is => 'ro',
    isa => Month,
);

has a_year => (
    is => 'ro',
    isa => Year,
);

1;
