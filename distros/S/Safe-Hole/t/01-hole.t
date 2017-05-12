use strict;
use warnings;
use Test::More tests => 33;

use_ok('Safe::Hole');
use Safe;
use Opcode qw( opmask_add opset );


# Test construction
my $safe = Safe->new;
isa_ok($safe, 'Safe');

my $hole = Safe::Hole->new({});
isa_ok($hole, 'Safe::Hole');

# Test visibility of root namespace
our $v;
isnt(\$v, $safe->reval('\$v'), 'Test visibility of root namespace');
is($@, '', "Reval \$v");

sub v { eval '\$v' };

is(\$v, $hole->call(\&v), "\$hole->call returns \\\$v");

$hole->wrap(sub{ eval '\$v' },$safe,'&v_wrapped');
$safe->share('&v');

isnt(\$v, $safe->reval('v()'), "\$save->reval('v()') returns \$v");
is($@, '', "No error on reval call");

is(\$v, $safe->reval('v_wrapped()'), "\$safe->reval('v_wrapped()') returns \$v");
is($@, '', "No error on reval(vrwapped) call");

# First check Safe works as we expect
my $op = '"Somthing innocuous"';
sub do_op { eval $op; $@ }
$safe->share('&do_op');

ok(!$safe->reval('do_op()'), q{$safe->reval('do_op()') returns false});
$op = 'eval "#Something forbidden"';
ok($safe->reval('do_op()'), q{$safe->reval('do_op()') retuns true after doing an invalid eval});

# Check Safe::Hole clears the opmask
$hole->wrap(\&do_op,$safe,'&do_op_wrapped');
ok(!$safe->reval('do_op_wrapped()'), q{Check Safe::Hole clears the opmask});

# Reality: check eof allowed
$op = 'eof';
ok($safe->reval('do_op()'), 'Reality: check eof allowed');

# Disable one opcode
opmask_add(opset('eof'));
# Make sure that opmask is restored
$hole->call(sub{});

# Disabled opcode propagates into Safe compartment
ok($safe->reval('do_op()'), 'Disabled opcode propagates into Safe compartment');

# Disabled opcode is not disabled via $hole
ok(!$hole->call(\&do_op), 'Disabled opcode is not disabled via $hole');

# Now create a Safe::Hole with a saved opmask
my $hole2 = Safe::Hole->new({});
isa_ok($hole2, "Safe::Hole", '$hole2');

# Sanity check it works at all
is(666, $hole2->call(sub{ 666 }), '$hole2->call(sub{ 666 }) returns 666');

$op = 'length';
ok(!$hole2->call(\&do_op), '$hole2->call(do_op) returns false');

$op = 'eof';
ok($hole2->call(\&do_op), '$hole2->call(\&do_op) returns true');

$hole2->wrap(\&do_op,$safe,'&do_op_wrapped2');

# We can still get at forbidden op via $hole...
ok(!$safe->reval('do_op_wrapped()'), 'We can still get at forbidden op via $hole');
# ...but not via $hole2
ok($safe->reval('do_op_wrapped2()'), '...but not via $hole2');

# Check argument and return passing
is($hole2->call(sub{ @{$_[2]} },undef,undef,[ 11 .. 15]), 5, 'Check argument and return passing (5)');
is(($hole->call(sub{ map { $_ + shift } 10..15 },20..25))[2], 34, 'Check argument and return passing (34)');

# Check exception handling of die
my $did_not_die;
eval { $hole2->call(sub{die "XXX\n"}); $did_not_die++ };
is($did_not_die, undef, 'Check exception handling of die - eval doesn\'t cause die');
is($@, "XXX\n", "\$\@ is populated");

##############################
# Backward compatible mode
###############################

my $old_hole = new Safe::Hole;
isa_ok($old_hole, 'Safe::Hole', 'New hole');
$::v = 'v in main';

is($old_hole->call( sub { eval '$v' }), 'v in main', "backwards compatible - old_hole");

# Alternate root
my $old_hole2 = new Safe::Hole 'foo';
isa_ok($old_hole, 'Safe::Hole', 'New hole alternate root');
$foo::v = 1; # added to prevent warning: 'Name "foo::v" used only once: possible typo at t/01-hole.t line 107.'
$foo::v = 'v in foo';
is($old_hole2->call( sub { eval '$v' }), 'v in foo', 'v in foo - alternate root');

# Check opcode mask not restored in backward compatible mode
$op='eval "#Something forbidden"'; 
$old_hole->wrap(\&do_op,$safe,'&do_op_wrapped_old');
ok($safe->reval('do_op_wrapped_old()'), q{$safe->reval('do_op_wrapped_old()')});

###################################
# Test that require works
##################################
$hole->wrap(sub { require File::Find; 1 },$safe,'&do_require');
ok(!($INC{'File/Find.pm'} || !$safe->reval('do_require') || !$INC{'File/Find.pm'}), 'Test that require works');

##################################
# Test that *INC not localised when it shouldn't be
##################################
$old_hole->wrap(sub { no strict; my $inc='INC'; "@{[%$inc]}" },$safe,'&get_inc');
is($safe->reval('%INC = ( FOO => "./FOO.pm" ); &get_inc'), 'FOO ./FOO.pm', '%INC = ( FOO => "./FOO.pm" );');

###################################
# Test wrapping of objects
##################################

# To do

