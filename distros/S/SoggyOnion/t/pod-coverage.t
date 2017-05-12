#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.04";

my @plugin_methods = qw( content init mod_time id new );
my %modules        = (
    'SoggyOnion'                       => [qw(generate useragent)],
    'SoggyOnion::Resource'             => [qw(new)],
    'SoggyOnion::Plugin'               => [qw(new)],
    'SoggyOnion::Plugin::GeoWeather'   => \@plugin_methods,
    'SoggyOnion::Plugin::ImageScraper' => \@plugin_methods,
    'SoggyOnion::Plugin::RSS'          => \@plugin_methods,
);

sub r {
    [ map {qr{\A $_ \Z}x} @_ ];
}

plan $@
    ? (
    skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" )
    : ( tests => scalar keys %modules );

while ( my ( $package, $methods ) = each %modules ) {
    pod_coverage_ok( $package, { trustme => r(@$methods) } );
}

