use Test::More tests => 40;
use Test::Trap;
use lib '../lib';

use Ouch qw(:trytiny_var);

eval { ouch(100, 'Test', 'field_name') };
($_, $@) = ($@);
isa_ok $_, 'Ouch';

is $_->code, 100, 'fetch code';
is kiss(100), 1, 'trap an ouch';
is kiss(101), 0, 'do not trap wrong ouch';
is hug(), 1, 'hug catches ouch';
is $_->message, 'Test', 'fetch message';
is $_->data, 'field_name', 'fetch data';
like $_, qr/^Test at/, 'string overload works';
isa_ok $_->hashref, 'HASH';
ok $_->trace, 'got a stack trace';
is bleep(), 'Test', 'can get a clean message for an ouch';

# what if it's not an ouch;
eval { die 'crap' };
($_, $@) = ($@);
is kiss(100), 0, 'do not trap non-ouch';
is bleep(), 'crap', 'can get the message for a non-ouch';
is hug(), 1, 'hug catches non-ouch';

# work out the traditional stuff
use Ouch qw(:traditional);

my $e = try {
  throw 100, 'Yikes';
};
$@ = undef; # ensure we really get to use $e
($_, $@) = ($@);
isa_ok $e, 'Ouch';
is hug(), 0, 'hug on reset $@ passes';
is hug($e), 1, 'hug on passed Ouch object works';
is bleep($e), 'Yikes', 'bleep on passed ouch works';

is catch(100, $e), 1, 'catch works';
is catch(101, $e), 0, 'catch works when not trapped';
is catch_all($e), hug($e), 'catch_all does the same as hug';

# what if the exception is a plain old one
$e = try { die 'Aaagh' };
$@ = undef; # ensure we really get to use $e
ok !ref($e), 'exception is not blessed when using die';
is bleep($e), 'Aaagh', 'bleep on plain string works';

# what if there is no exception
$e = try { my $x = 1 };
is hug(), 0, 'hug does not catch lack of exception (using default $@)';
try { throw 100, 'Ohfff' }; # make sure $@ is set
is hug($e), 0, 'hug does not catch lack of exception';
is catch_all($e), hug($e), 'catch_all does the same as hug';

# what if the exception code is a string
eval { ouch('missing_param', 'Email'); };
($_, $@) = ($@);
is kiss('missing_param'), 1, 'kiss works on strings';
is kiss('foo'), 0, 'kiss gives no false positives';

# barf
trap { eval { ouch(100, 'oops') } or do { ($_, $@) = ($@); barf() } };
($_, $@) = ($@);
is $trap->exit, 100, 'exit code';
is $trap->stderr, "oops\n", 'stderr err message';

# more barf
trap { eval { die 'error' } or do { ($_, $@) = ($@); barf() } };
($_, $@) = ($@);
is $trap->exit, 1, 'default barf exit code';
is $trap->stderr, "error\n", 'stderr err message w/o ouch';

package OtherPackage;
use Test::More;
use Test::Trap;
use lib '../lib';
use Ouch;

eval { ouch(100, 'Whatever') };
is kiss(100), 1, 'trap an ouch, back to $@ in different package';
is kiss(101), 0, 'do not trap wrong ouch, $@';
trap { eval { ouch(100, 'oops') } or barf() };
is $trap->exit, 100, 'exit code, $@';
is $trap->stderr, "oops\n", 'stderr err message, $@';

package main;

eval { ouch(100, 'Whatever') };
($_, $@) = ($@);
is kiss(100), 1, 'trap an ouch, back to $_ in main package';
is kiss(101), 0, 'do not trap wrong ouch, $_ in main package';
trap { eval { ouch(100, 'oops') } or do { ($_, $@) = ($@); barf() } };
is $trap->exit, 100, 'exit code, $_ in main package';
is $trap->stderr, "oops\n", 'stderr err message, $_ in main package';
