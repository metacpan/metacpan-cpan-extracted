use strict;
use warnings;
use Test::More;
use Test::Exception;

{ package Class;
  use Moose;
  use MooseX::Types::Signal qw(Signal UnixSignal PerlSignal);

  my @has = ( is => 'rw', coerce => 1, isa => );

  has 'unix' => ( @has, UnixSignal );
  has 'perl' => ( @has, PerlSignal );
  has 'any'  => ( @has, Signal     );
}

my $test = Class->new;

# use Data::Dump::Streamer;
# diag(Data::Dump::Streamer->new->Dump(
#     MooseX::Types::Signal::perl_signals(),
#     MooseX::Types::Signal::unix_signals(),
# )->Names('$Perl', '$Unix')->Out);

# ok, so... if your platform does not map SIGKILL to 9, i hate it.
lives_ok {
    $test->unix('KILL');
    $test->perl('KILL');
    $test->any ('KILL');
} 'KILL is ok';

is $test->unix, 9, 'KILL => 9';
is $test->perl, 9, 'KILL => 9';
is $test->any,  9, 'KILL => 9';

lives_ok {
    $test->unix('SIGKILL');
    $test->perl('SIGKILL');
    $test->any ('SIGKILL');
} 'SIGKILL is ok';

is $test->unix, 9, 'SIGKILL => 9';
is $test->perl, 9, 'SIGKILL => 9';
is $test->any,  9, 'SIGKILL => 9';

lives_ok {
    $test->unix('sIgKiLL');
    $test->perl('sIgKiLL');
    $test->any ('sIgKiLL');
} 'sIgKiLL is ok';

is $test->unix, 9, 'sIgKiLL => 9';
is $test->perl, 9, 'sIgKiLL => 9';
is $test->any,  9, 'sIgKiLL => 9';

lives_ok {
    $test->unix(9);
    $test->perl(9);
    $test->any(9);
} '9 is ok';

is $test->unix, 9, '9 => 9';
is $test->perl, 9, '9 => 9';
is $test->any,  9, '9 => 9';

throws_ok {
    $test->unix(0);
} qr/signal #0 is not a meaningful UNIX signal/, 'no unix 0';

throws_ok {
    $test->unix(31337);
} qr/signal 31337 is not listed/, 'no unix 31337';

lives_ok {
    $test->perl(0);
} 'sig 0 exists in perl land';

throws_ok {
    $test->perl(31337);
} qr/signal 31337 is not mentioned/, 'no perl 31337';

throws_ok {
    $test->unix('LOLCAT');
} qr/LOLCAT could not be coerced to a unix signal/, 'no unix SIGLOLCAT';

throws_ok {
    $test->perl('LOLCAT');
} qr/LOLCAT could not be coerced to a perl signal/, 'no unix SIGLOLCAT';

done_testing;
