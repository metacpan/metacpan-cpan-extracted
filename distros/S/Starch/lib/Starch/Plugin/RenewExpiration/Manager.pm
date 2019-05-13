package Starch::Plugin::RenewExpiration::Manager;
our $VERSION = '0.14';

use Types::Common::Numeric -types;
use Types::Common::String -types;

use Moo::Role;
use strictures 2;
use namespace::clean;

with 'Starch::Plugin::ForManager';

has renew_threshold => (
    is      => 'ro',
    isa     => PositiveOrZeroInt,
    default => 0,
);

has renew_variance => (
    is      => 'ro',
    isa     => PositiveOrZeroNum,
    default => 0,
);

has renew_state_key => (
    is      => 'ro',
    isa     => NonEmptySimpleStr,
    default => '__STARCH_RENEW__',
);

1;
