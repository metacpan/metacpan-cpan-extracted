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

# 2: Test function interface to randregex()
is(String::Random::random_regex("[a][b][c]"), "abc", "random_regex()");

# Test regex support
for (@patterns) {
    my $ret=String::Random::random_regex($_);
    ok($ret =~ /^$_$/, "random_regex('$_')")
        or diag "'$_' failed, '$ret' does not match.\n";
}

# Test random_regex, this time passing an array.
my @ret=String::Random::random_regex(@patterns);
is(@ret, @patterns, "random_regex() return")
    or diag "random_regex() returned a different array size!";

for (my $n=0;$n<@patterns;$n++) {
    ok(defined($ret[$n]), "defined random_regex('$patterns[$n]')");
    ok($ret[$n] =~ /^$patterns[$n]$/, "random_regex('$patterns[$n]')")
        or diag "'$patterns[$n]' failed, '$ret[$n]' does not match.\n";
}

# vi: set ai et syntax=perl:
