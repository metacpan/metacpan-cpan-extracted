#!/usr/bin/env perl
package Class;
use strict;
use warnings;

use Test::More tests => 4;

use Moose;
use DateTime::TimeZone;
use MooseX::Types::DateTime::ButMaintained qw(TimeZone);
has 'foo' => ( isa => 'DateTime::TimeZone', is => 'ro', required => 1, coerce => 1 );

is ( '+0200', Class->new({ foo => 'CEST' })->foo->name, 'CEST returned right name' );
is ( '7200', Class->new({ foo => 'CEST' })->foo->offset_for_datetime, 'CEST returned right offset' );

eval { Class->new({ foo => 'EST' }); };
like ( $@, qr/ambigious/i, 'EST is ambigious and has caused death!!' );

eval { Class->new({ foo => 'ZZX' }); };
like ( $@, qr/unknown/i, 'ZZX is unknown and has caused death!!' );
