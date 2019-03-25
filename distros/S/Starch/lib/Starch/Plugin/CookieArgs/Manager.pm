package Starch::Plugin::CookieArgs::Manager;
use 5.008001;
use strictures 2;
our $VERSION = '0.13';

use Types::Standard -types;
use Types::Common::String -types;
use Types::Common::Numeric -types;

use Moo::Role;
use namespace::clean;

with qw(
    Starch::Plugin::ForManager
);

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
