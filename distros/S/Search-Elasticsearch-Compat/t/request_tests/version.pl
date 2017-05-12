#!perl

use Test::More;
use strict;
use warnings;
our ( $es, $es_version );
my $r;

isa_ok $r = $es->current_server_version, 'HASH', 'Current server version';
ok $r->{number}, ' - has a version string';

note "Current server is "
    . ( $r->{snapshot_build} ? 'development ' : '' )
    . "version "
    . $r->{number};

$es_version = $r->{number};

1;
