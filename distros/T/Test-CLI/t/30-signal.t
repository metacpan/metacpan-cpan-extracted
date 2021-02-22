use strict;
use warnings;
use Test::More;
use Test::Exception;
use Path::Tiny;

use Test::CLI qw< tc >;

$|++;
my $sparring = path(__FILE__)->parent->child('sparring')->stringify;

my $tc = tc($sparring, qw{ <channel=stdout> <exit> [stuff] });

$tc->run(exit => 0);
$tc->signal_ok
   ->signal_is(0)
   ->signal_isnt(9);

$tc->run(exit => -9);
$tc->signal_failure_ok
   ->signal_is(9)
   ->signal_isnt(10)
   ->signal_isnt(0);

done_testing();
