#!perl -T

use Tatsumaki::Template::Markapl;
use Test::More;

use_ok('Tatsumaki::Template::Markapl');
can_ok('Tatsumaki::Template::Markapl', 'rewrite');

done_testing;
