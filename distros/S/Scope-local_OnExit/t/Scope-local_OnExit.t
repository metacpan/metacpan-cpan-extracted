# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Scope-local_OnExit.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 8 };
use Scope::local_OnExit;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

our $counter = 7;
our $should_val;
sub Has{
   local $OnExit = sub {$counter--};
   ok($counter==$should_val)
}
$should_val=$counter;
Has;
ok(--$should_val == $counter);
sub dies {
   local $OnExit = sub {die "I TOLD YOU I WAS SICK"};
   $should_val=$counter;
   Has;
}
eval { dies };
ok ( $@ =~ m/SICK/ );

# five tests above here

our $OE;
tie $OE, 'Scope::local_OnExit';
my $eres = eval { $OE = 99 ; 1 };
my $exc = $@;
# warn "eres: $eres exc: $exc";
ok ( !$eres );
ok ( $exc =~ m/underflow/ );
my $file = __FILE__;
ok ( $exc =~ m/$file/ );



