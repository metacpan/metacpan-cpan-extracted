#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;
use Config;
my $perl = $Config{perlpath};

use lib 'lib';
$ENV{PERL5LIB} = 'lib';

$ENV{MORPHEUS} = q@
    '/foo/bar' => 5,
    '/x' => { 'y' => 6, 'z' => { t => 7 } },
@;

my $result;

$result = qx($perl bin/morph /foo);
is(
    $result,
'{
   "bar" : 5
}
',
    'morph without arguments prints json'
);

$result = qx($perl bin/morph /foo/bar);
like(
    $result,
    qr/^(5|"5")\n$/,
    'morph without arguments prints json'
);

$result = qx($perl bin/morph --format=dumper /foo);
like(
    $result,
    qr/^\s*{\s*'bar'\s*=>\s*5\s*}\s*$/,
    'morph with dumper format'
);

# TODO - test xml and tt2 formats
