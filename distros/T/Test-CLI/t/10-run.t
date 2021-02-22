use strict;
use warnings;
use Test::More;
use Test::Exception;
use Path::Tiny;

use Test::CLI qw< tc >;

$|++;
my $sparring = path(__FILE__)->parent->child('sparring')->stringify;

my $tc = tc($sparring, qw{ <channel=stdout> <exit=0> [stuff] });
isa_ok $tc, 'Test::CLI';

ok $tc->run, 'plain run';

$tc->run_ok;
$tc->run_ok({stuff => 'blah'});
$tc->run_ok({stuff => 'blah'}, 'invoke with blah');
$tc->exit_code_ok
   ->exit_code_is(0)
   ->exit_code_isnt(1)
   ->signal_ok
   ->stderr_unlike(qr{.});

my $ftc = tc($sparring, qw{ <channel=stderr> <exit=1> [stuff]});
isa_ok $ftc, 'Test::CLI';

$ftc->run_failure_ok;
$ftc->run_failure_ok({stuff => 'bar'});
$ftc->run_failure_ok({stuff => 'bar'}, 'run false command with parameter');
$ftc->exit_code_is(1);
$ftc->exit_code_failure_ok;

my $ttc = tc($sparring, qw{ <channel=stdout> <exit=0> [stuff]});
$ttc->run_ok({stuff => 'whatever'})
   ->stdout_is("whatever")
   ->stdout_like(qr{what[\w]ver})
   ->merged_like(qr{^what})
   ->stderr_unlike(qr{.});

$ttc->verbose(1);
$ttc->run_ok({stuff => "what ever you do\ndo\nit\nright\n"})
   ->stdout_like(qr{\bit\b}, 'check on other run');

done_testing();


