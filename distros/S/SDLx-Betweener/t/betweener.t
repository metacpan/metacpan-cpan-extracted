
use strict;
use warnings;

use Test::More;

BEGIN { use_ok('SDLx::Betweener') };

my $tweener = SDLx::Betweener->new;

{ # tween_int direct proxy

my $v = -1;
my $tween = $tweener->tween_int(t=>10, range=>[0,100], on=>\$v);
$tween->start(5);
is $v, 0, 'int 1d direct tick 0';
$tweener->tick(7);
is $v, 20, 'int 1d direct tick 1';

}

{ # tween_int callback proxy

my $v = -1;
my $tween = $tweener->tween_int(t=>10, range=>[1,100], on=>sub{ $v = shift });
$tween->start(0);
is $v, 1, 'int 1d callback tick 0';
$tweener->tick(9);
is $v, 90, 'int 1d callback tick 1';

}

package Betweener::t::MockTweenable;
use Moose;
has v => (is => 'rw', default => -1);

package main;

{ # tween_int method proxy

my $o = Betweener::t::MockTweenable->new;
my $tween = $tweener->tween_int(t=>10, range=>[1,100], on=>{v=>$o});
$tween->start(0);
is $o->v, 1, 'int 1d method tick 0';
$tweener->tick(9);
is $o->v, 90, 'int 1d method tick 1';

}

{ # tween_float direct proxy

my $v = 10.0; # must specify as float
my $tween = $tweener->tween_float(t=>300, to=>15.0, on=>\$v, ease=>'linear');
$tween->start(100);
is $v, 10, 'float 1d direct tick 0';
$tweener->tick(250);
is $v, 12.5, 'float 1d direct tick 1';

}


done_testing;
