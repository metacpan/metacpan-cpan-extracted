#!perl -T
use 5.010;
use strict;
use warnings FATAL => 'all';

use Test::More tests => 6;
use Test::Fatal;

use Statistics::R::REXP::List;
use Statistics::R::REXP::Character;
use Statistics::R::REXP::Double;
use Statistics::R::REXP::Integer;

my $empty_list = new_ok('Statistics::R::REXP::List', [  ], 'new generic vector' );

ok(! ($empty_list->attributes && $empty_list->attributes->{'class'}), 'no class');
ok(! $empty_list->inherits('foo'), 'no inheritance');

my $obj = Statistics::R::REXP::List->new(elements => [3.3, '4', 11],
                                         attributes => {
                                             class => Statistics::R::REXP::Character->new([
                                                 'foo', 'data.frame' ]),
                                             names => Statistics::R::REXP::Character->new([
                                                 'a', 'b', 'g' ]),
                                         });
ok( $obj->inherits('foo'));
ok( $obj->inherits('data.frame'));
ok( !$obj->inherits('bar'));
