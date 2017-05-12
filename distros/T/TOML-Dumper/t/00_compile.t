use strict;
use Test::More 0.98;

use_ok $_ for qw(
    TOML::Dumper
    TOML::Dumper::Context
    TOML::Dumper::Context::Array
    TOML::Dumper::Context::Array::Inline
    TOML::Dumper::Context::Root
    TOML::Dumper::Context::Table
    TOML::Dumper::Context::Table::Inline
    TOML::Dumper::Context::Value
    TOML::Dumper::Context::Value::Inline
    TOML::Dumper::Name
    TOML::Dumper::String
);

done_testing;

