#!perl

use strict;
use warnings;

use Test::More tests => 1;
use Perlbal::Plugin::ExpandSSL;

my @pem = (
    '-----BEGIN CERTIFICATE-----',
    'this is the real beginning',
    'this is another line',
    'third line, almost last',
    'before last line',
    '',
    '-----END CERTIFICATE-----',
);

my $pem = Perlbal::Plugin::ExpandSSL::serialize_pem(@pem);

pop   @pem for 1, 2;
shift @pem;

my $my_pem = join "\n", @pem;

is( $pem, "$my_pem\n", 'serialize_pem works' );

