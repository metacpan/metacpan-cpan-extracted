package Stancer::Core::Types::String::Stub;

use 5.020;
use strict;
use warnings;

use Moo;
use namespace::clean;

use Stancer::Core::Types::String qw(:all);

has a_char_10 => (
    is => 'ro',
    isa => Char[10],
);

has a_description => (
    is => 'ro',
    isa => Description,
);

has an_email => (
    is => 'ro',
    isa => Email,
);

has an_external_id => (
    is => 'ro',
    isa => ExternalId,
);

has a_mobile => (
    is => 'ro',
    isa => Mobile,
);

has a_name => (
    is => 'ro',
    isa => Name,
);

has an_order_id => (
    is => 'ro',
    isa => OrderId,
);

has an_unique_id => (
    is => 'ro',
    isa => UniqueId,
);

has a_varchar_5_to_10 => (
    is => 'ro',
    isa => Varchar[5, 10],
);

has a_varchar_10_to_5 => (
    is => 'ro',
    isa => Varchar[10, 5],
);

has a_varchar_10 => (
    is => 'ro',
    isa => Varchar[10],
);

1;
