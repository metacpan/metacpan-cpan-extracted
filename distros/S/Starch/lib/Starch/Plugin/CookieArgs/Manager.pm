package Starch::Plugin::CookieArgs::Manager;
our $VERSION = '0.14';

use Types::Common::Numeric -types;
use Types::Common::String -types;
use Types::Standard -types;

use Moo::Role;
use strictures 2;
use namespace::clean;

with 'Starch::Plugin::ForManager';

has cookie_name => (
    is      => 'ro',
    isa     => NonEmptySimpleStr,
    default => 'session',
);

has cookie_domain => (
    is => 'ro',
    isa => (NonEmptySimpleStr) | Undef,
);

has cookie_path => (
    is  => 'ro',
    isa => (NonEmptySimpleStr) | Undef,
);

has cookie_secure => (
    is      => 'ro',
    isa     => Bool,
    default => 1,
);

has cookie_http_only => (
    is      => 'ro',
    isa     => Bool,
    default => 1,
);

1;
