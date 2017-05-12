#!perl
use strict;
use Test::More;
use Net::YASA;
use Module::Build;
use utf8;

my $mb = Module::Build->current();
if ( !$mb->feature('json_support') or !$mb->notes('jsontests') ) {
    plan skip_all => 'No JSON driver installed';
}
plan tests => 3;

use_ok( 'JSON::Any');
my $ny = Net::YASA->new( output => 'json' );
my $termset = $ny->extract("我要去上學我想去上學");
like ($$termset[0]{'Term'}, qr/去上學/, 'Content from extraction');
is ($$termset[0]{'Freq'}, 2, 'Frequency from extraction');
diag( "Testing Net::YASA function, extract in json format");

