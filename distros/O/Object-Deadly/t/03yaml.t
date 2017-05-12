#!perl
use Test::More;

if ( not $ENV{AUTHOR_TESTS} ) {
    plan skip_all => 'Skipping author tests';
}
else {
    plan tests => 1;
    require YAML;
    YAML->import('LoadFile');

    ok( LoadFile("META.yml") );
}
