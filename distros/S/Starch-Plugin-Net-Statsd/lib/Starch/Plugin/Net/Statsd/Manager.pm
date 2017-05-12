package # hide from PAUSE
    Starch::Plugin::Net::Statsd::Manager;

use Types::Common::String -types;
use Types::Common::Numeric -types;

use Moo::Role;
use strictures 2;
use namespace::clean;

with qw(
    Starch::Plugin::ForManager
);

has statsd_host => (
    is  => 'ro',
    isa => NonEmptySimpleStr,
);

has statsd_port => (
    is  => 'ro',
    isa => PositiveInt,
);

has statsd_root_path => (
    is      => 'ro',
    isa     => NonEmptySimpleStr,
    default => 'starch',
);

has statsd_sample_rate => (
    is      => 'ro',
    isa     => PositiveOrZeroNum,
    default => 1,
);

1;
