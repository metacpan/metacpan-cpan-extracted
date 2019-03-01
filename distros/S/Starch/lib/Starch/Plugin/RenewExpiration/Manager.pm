package Starch::Plugin::RenewExpiration::Manager;
use 5.008001;
use strictures 2;
our $VERSION = '0.12';

use Types::Common::String -types;
use Types::Common::Numeric -types;

use Moo::Role;
use namespace::clean;

with qw(
    Starch::Plugin::ForManager
);

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
