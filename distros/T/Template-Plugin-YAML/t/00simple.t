#!perl -w
use strict;
use Test::More tests => 3;
use Template;
use YAML;

my $tt = new Template;
my $out;
my $data = [ { foo => 'bar' }, { foo => 'baz' } ];
ok( $tt->process(
        \"[% USE YAML %][% YAML.dump( struct ) %]", { struct => $data, },
        \$out
    ),
    "TT ran"
);

ok( !$tt->error, "  without error" );

is_deeply( YAML::Load($out), $data, "YAML round tripped to original data" );
