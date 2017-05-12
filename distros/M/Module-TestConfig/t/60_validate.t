# -*- perl -*-

use Test::More tests => 11;
#use Test::More 'no_plan';

use Module::TestConfig;
use Test::Warn;

$ENV{TESTCONFIG_FIVE} ||= 5;

# Validations
$isnum = qr/^\d+$/;
sub notx { shift() ne 'x' }

# Main tests
ok $t = Module::TestConfig->new( questions => [
	[ qw/One?   one/, { validate => { callbacks => { 'exactly 1' => sub { shift() == 1 }}}} ],
	[ qw/Two?   two/, { validate => { callbacks => { 'exactly 2' => sub { shift() == 2 }}}} ],
	[ qw/Three? three x/, { validate => { regex => $isnum } } ],
	[ qw/Four?  four  4/, { validate => { regex => $isnum } } ],
	[ qw/Five?  testconfig_five x/, { validate => { regex => $isnum }} ],
   ],
   order => [ qw/env defaults/ ],
   defaults => 't/etc/defaults.config',
), 				"new()";

close STDIN or warn $!;		# query noninteractively.

ok $t->ask,			 "ask()";
is $t->answer( 'one' ), 1,	 "answer(1) from file";
is $t->answer( 'two' ), 2,	 "answer(2) from file";
is $t->answer( 'three' ), 3,	 "answer(3) from file";
is $t->answer( 'four' ), 4,	 "answer(4) from default";
is $t->answer( 'testconfig_five' ), 5,	 "answer(5) from env";

# these should fail:

ok $will_fail = Module::TestConfig->new( questions => [
    [ 'Type a number:', qw/num x/, { validate => { regex => $isnum }} ],
    [ "Don't type x:", qw/cb x/,   { validate => { callbacks => { 'not x' => \&notx }}} ],
  ],
),				 "question with a regex validation that should fail";

# XXX Test::Warn-0.07 warnings_are() doesn't understand warnings with
#     newlines. This is a workaround:
chomp( my @warnings = <DATA> );
warnings_like { $will_fail->ask } [ map { qr/\Q$_/ } @warnings ],  'ask()';

isnt $will_fail->answer('num'), 'x',	"num shouldn't be set to 'x'";
isnt $will_fail->answer('cb'),  'x',	"cb  shouldn't be set to 'x'";


# Warnings follow:
#
# For some reason, the test doesn't work when I interleave the
# following warnings. It's as if they're not getting sent as
# a warning; I'm a little confused.
#
#   The 'num' parameter not pass regex check
#   The 'cb' parameter not pass the 'not x' callback
__DATA__
Your answer didn't validate.
Please try again. [Attempt 1]
Your answer didn't validate.
Please try again. [Attempt 2]
Your answer didn't validate.
Please try again. [Attempt 3]
Your answer didn't validate.
Please try again. [Attempt 4]
Your answer didn't validate.
Please try again. [Attempt 5]
Your answer didn't validate.
Please try again. [Attempt 6]
Your answer didn't validate.
Please try again. [Attempt 7]
Your answer didn't validate.
Please try again. [Attempt 8]
Your answer didn't validate.
Please try again. [Attempt 9]
Your answer didn't validate.
Please try again. [Attempt 10]
Your answer didn't validate.
Let's just skip that question, shall we?
Your answer didn't validate.
Please try again. [Attempt 1]
Your answer didn't validate.
Please try again. [Attempt 2]
Your answer didn't validate.
Please try again. [Attempt 3]
Your answer didn't validate.
Please try again. [Attempt 4]
Your answer didn't validate.
Please try again. [Attempt 5]
Your answer didn't validate.
Please try again. [Attempt 6]
Your answer didn't validate.
Please try again. [Attempt 7]
Your answer didn't validate.
Please try again. [Attempt 8]
Your answer didn't validate.
Please try again. [Attempt 9]
Your answer didn't validate.
Please try again. [Attempt 10]
Your answer didn't validate.
Let's just skip that question, shall we?
