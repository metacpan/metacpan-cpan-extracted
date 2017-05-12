use Test::More tests => 6;

BEGIN {
    use_ok($_) for qw(
        SoggyOnion
        SoggyOnion::Resource
        SoggyOnion::Plugin
        SoggyOnion::Plugin::GeoWeather
        SoggyOnion::Plugin::ImageScraper
        SoggyOnion::Plugin::RSS
    );
}
