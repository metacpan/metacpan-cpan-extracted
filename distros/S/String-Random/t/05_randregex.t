use strict;
use warnings;

use vars qw(@patterns);

BEGIN {
    @patterns=(
        '\d\d\d',
        '\w\w\w',
        '[ABC][abc]',
        '[012][345]',
        '...',
        '[a-z][0-9]',
        '[aw-zX][123]',
        '[a-z]{5}',
        '0{80}',
        '[a-f][nprt]\d{3}',
        '\t\n\r\f\a\e',
        '\S\S\S',
        '\s\s\s',
        '\w{5,10}',
        '\w?',
        '\w+',
        '\w*',
        '',
    );
}

use Test::More tests => (3 * @patterns + 3);

# 1: Make sure we can load the module
BEGIN { use_ok('String::Random'); }

# 2: Make sure we can create a new object
my $foo=new String::Random;
ok(defined($foo), "new()");

# Test regex support
for (@patterns) {
    my $ret=$foo->randregex($_);
    ok($ret =~ /^$_$/, "randregex('$_')")
        or diag "'$_' failed, '$ret' does not match.\n";
}

# Test regex support, but this time pass an array.
my @ret=$foo->randregex(@patterns);
is(@ret, @patterns, "randregex() return")
    or diag "randregex() returned a different array size!";

for (my $n=0;$n<@patterns;$n++) {
    ok(defined($ret[$n]), "defined randregex('$patterns[$n]')");
    ok($ret[$n] =~ /^$patterns[$n]$/, "randregex('$patterns[$n]')")
        or diag "'$patterns[$n]' failed, '$ret[$n]' does not match.\n";
}

# vi: set ai et syntax=perl:
