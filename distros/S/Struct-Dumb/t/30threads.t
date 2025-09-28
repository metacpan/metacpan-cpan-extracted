#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
use Test2::IPC; # perform thread init

eval { require Config && $Config::Config{useithreads} } or
   plan skip_all => "This perl does not support threads";

# Tests whether the presence of Struct::Dumb instances will upset thread
# cloning. Related to
#   https://rt.cpan.org/Ticket/Display.html?id=170460
#   https://github.com/Perl/perl5/issues/23771

use Struct::Dumb;
require threads;

struct Point => [qw( x y )];

my $point = Point(10, 20);

my $values = threads->create(sub {
   return [ $point->x, $point->y ];
})->join;
is( $values, [ 10, 20 ], 'Point struct survives thread cloning' );

done_testing;
