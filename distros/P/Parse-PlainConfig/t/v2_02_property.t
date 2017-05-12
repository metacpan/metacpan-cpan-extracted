#!/usr/bin/perl -T
# 02_property.t

use Test::More tests => 34;
use Paranoid;
use Parse::PlainConfig::Legacy;

use strict;
use warnings;

psecureEnv();

my $conf        = new Parse::PlainConfig::Legacy;
my %properties  = (
    PARAM_DELIM     => '*',
    LIST_DELIM      => ':',
    HASH_DELIM      => '>',
    AUTOPURGE       => 1,
    SMART_PARSER    => 1,
    PADDING         => 3,
    FILE            => 'foo',
    MTIME           => 3,
    );
my ($key, $value, %tmp);

# Test setting bad properties/values
ok( !eval '$conf->property( FOO => "bar" )', 'bad property 1');
ok( !$conf->property( PARAM_DELIM => [] ), 'bad property 2');
ok( !$conf->property( ORDER => "foo" ), 'bad property 3');
ok( !$conf->property( COERCE => [] ), 'bad property 4');
ok( !$conf->property( COERCE => { FOO => 'bar' } ), 'bad property 5');

# Test valid properties
while ( ( $key, $value ) = each %properties ) {
    isnt( $conf->property( $key ), $value, "property $key default value" );
    ok( $conf->property( $key => $value ), "property $key set");
    is( $conf->property( $key ), $value, "property $key value $value");
}
ok( $conf->property( ORDER => [ qw(FOO BAR ROO) ] ), 'property ORDER set');
($key, $value) = @{ $conf->property( 'ORDER' ) };
is( $value, 'BAR', 'property ORDER get');
ok( $conf->property( COERCE => {
    FOO => 'list',
    BAR => 'string',
    ROO => 'hash',
    }), 'property COERCE set');
%tmp = %{ $conf->property( 'COERCE' ) };
is( $tmp{FOO}, 'list', 'property COERCE get');
ok( $conf->property( MAX_BYTES => 512 ), 'property MAX_BYTES set' );

# end 02_property.t
