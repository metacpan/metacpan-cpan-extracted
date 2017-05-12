#!perl

use Test::More;
use Test::Deep;
use Proc::PidChange ':all';

my %calls;
my $cb1 = sub { $calls{cb1}++ };
my $cb2 = sub { $calls{cb2}++ };
my $cb3 = sub { $calls{cb3}++ };

Proc::PidChange::_call_all_callbacks();
cmp_deeply(\%calls, {}, 'at start, empty callback list');

register_pid_change_callback($cb1);
Proc::PidChange::_call_all_callbacks();
cmp_deeply(\%calls, { cb1 => 1 }, 'added callback 1 ok');

register_pid_change_callback($cb1, $cb2, $cb3);
Proc::PidChange::_call_all_callbacks();
cmp_deeply(\%calls, { cb1 => 3, cb2 => 1, cb3 => 1 }, 'added multiple callbacks ok');

unregister_pid_change_callback($cb2);
Proc::PidChange::_call_all_callbacks();
cmp_deeply(\%calls, { cb1 => 5, cb2 => 1, cb3 => 2 }, 'removed callback 2 ok');

unregister_pid_change_callback($cb1, $cb2, $cb3);
Proc::PidChange::_call_all_callbacks();
cmp_deeply(\%calls, { cb1 => 5, cb2 => 1, cb3 => 2 }, 'remove multiple callbacks ok');


done_testing();
