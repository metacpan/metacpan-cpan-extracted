use strict;
use warnings;

use Test::More tests => 37;

# 1: Make sure we can load the module
BEGIN { use_ok('String::Random'); }

# 2: Make sure we can create a new object
my $foo=new String::Random;
my $bar=String::Random->new();
ok(defined($foo) && defined($bar), "new()");

# 3: Empty pattern shouldn't give undef for result
ok(my @notempty=$foo->randpattern(''), "randpattern('')");

# Try the object method...
$foo->{'x'}=['a'];
$foo->{'y'}=['b'];
$foo->{'z'}=['c'];

# 4: passing a scalar, in a scalar context
my $abc=$foo->randpattern("xyz");
is($abc, 'abc', "randpattern()");

# 5: passing an array, in a scalar context
my @foo=qw(x y z);
$abc=$foo->randpattern(@foo);
is($abc, 'abc', "randpattern() (scalar)");

# 6-8: passing an array, in an array context
my @bar=$foo->randpattern(@foo);
for (my $n=0;$n<@foo;$n++) {
    is($bar[$n], $foo->{$foo[$n]}->[0], "randpattern() (array) ($n)");
}

# 9-34: Check one of the built-in patterns to make
# sure it contains what we think it should
my @upcase=("A".."Z");
for (my $n=0;$n<26;$n++) {
    ok(defined($foo->{'C'}->[$n]) && ($upcase[$n] eq $foo->{'C'}->[$n]),
        "pattern ($n)");
}

# 35: Test modifying one of the built-in patterns
$foo->{'C'}=['n'];
is($foo->randpattern("C"), "n", "modify patterns");

# 36: Make sure we haven't clobbered anything in an existing object
isnt($bar->randpattern("C"), "n", "pollute pattern");

# 37: Make sure we haven't clobbered anything in a new object
my $baz=new String::Random;
ok(defined($baz) && ($baz->randpattern("C") ne "n"), "pollute new object");

# vi: set ai et syntax=perl:
