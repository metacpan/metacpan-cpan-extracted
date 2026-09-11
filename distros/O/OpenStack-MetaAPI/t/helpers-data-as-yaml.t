#!/usr/bin/env perl

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use OpenStack::MetaAPI::Helpers::DataAsYaml;

# --- LoadDataFrom: undefined package ---
like(
    dies { OpenStack::MetaAPI::Helpers::DataAsYaml::LoadDataFrom(undef) },
    qr/undefined package/,
    "LoadDataFrom dies on undefined package"
);

# --- LoadDataFrom: package with no __DATA__ returns undef ---
{
    package FakePackage::NoData;
    1;
}

# Suppress the expected readline warning for packages with no DATA handle
my $result;
{
    local $SIG{__WARN__} = sub { };
    OpenStack::MetaAPI::Helpers::DataAsYaml::clear_cache();
    $result = OpenStack::MetaAPI::Helpers::DataAsYaml::LoadDataFrom('FakePackage::NoData');
}
is $result, undef, "LoadDataFrom returns undef for package with no __DATA__";

# --- LoadDataFrom: loads real YAML from Routes.pm ---
# NOTE: __DATA__ is consumed on first read, so we do all Routes tests in one
# block without clearing the cache between them.
{
    OpenStack::MetaAPI::Helpers::DataAsYaml::clear_cache();

    require OpenStack::MetaAPI::Routes;
    my $routes = OpenStack::MetaAPI::Helpers::DataAsYaml::LoadDataFrom('OpenStack::MetaAPI::Routes');

    ok ref $routes eq 'HASH', "LoadDataFrom returns a hashref for Routes";
    ok exists $routes->{servers},     "routes contains 'servers'";
    ok exists $routes->{floatingips}, "routes contains 'floatingips'";
    is $routes->{servers}{service},     'compute', "servers route maps to compute service";
    is $routes->{floatingips}{service}, 'network', "floatingips route maps to network service";

    # --- Caching: second call returns the same cached reference ---
    my $second = OpenStack::MetaAPI::Helpers::DataAsYaml::LoadDataFrom('OpenStack::MetaAPI::Routes');
    ok $routes == $second, "second call returns the same cached reference";
}

# --- clear_cache ---
{
    OpenStack::MetaAPI::Helpers::DataAsYaml::clear_cache();
    ok 1, "clear_cache does not die";
}

done_testing;
