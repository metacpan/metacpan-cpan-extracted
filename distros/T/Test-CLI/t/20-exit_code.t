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
$tc->exit_code_ok
   ->exit_code_is(0)
   ->exit_code_isnt(1);

$tc->run(exit => 42);
$tc->exit_code_failure_ok
   ->exit_code_is(42)
   ->exit_code_isnt(1)
   ->exit_code_isnt(0);

done_testing();
