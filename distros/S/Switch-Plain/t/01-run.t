#!perl
use warnings FATAL => 'all';
use strict;

use Test::More tests => 25;

use Switch::Plain;

is $_, undef;

my $r = 'fail';
nswitch (2) {
    case 1: { $r = '1' }
    case 2: {
        $r = 'ok';
    }
    case 3: {
        ;
        $r = '3';
    }
}
is $r, 'ok';
is $_, undef;

$r = 'fail';
my $x = int rand 100_000;
nswitch ($x) {
    case $x: { $r = 'ok' }
    default: { # nothing
    }
}
is $r, 'ok';
is $_, undef;

$r = 'fail';
$x = int rand 100_000;
nswitch (1 + $x * 2) {
    case $x: {}
    default: {
        $r = 'ok';
    }
}
is $r, 'ok';
is $_, undef;

$r = 'fail';
$x = int rand 100_000;
nswitch ($x) {
    case 1 + $x * 2: {}
    default: {
        $r = 'ok';
    }
}
is $r, 'ok';
is $_, undef;

my @words = qw(speed me towards death);
$r = 'fail';
sswitch ($words[1]) {
    case 0: {}
    case substr 'holmes', 3, 2: {
        ($r = $_) =~ tr/em/ko/;
    }
    case 'me': { $r = 'wtf'; }
}
is $r, 'ok';
is $_, undef;

$r = 'fail';
sswitch ($words[rand @words]) {
    case $words[0]:
    case $words[1]:
    case $words[2]:
    case $words[3]: {
        $r = 'ok';
    }
    default: {
        $r = 'wtf';
    }
}
is $r, 'ok';
is $_, undef;

$r = 'fail';
sswitch ($words[rand @words]) {
    default if /^${\join '|', map { quotemeta } @words}\z/: {
        $r = 'ok';
    }
    default: {
        $r = 'wtf';
    }
}
is $r, 'ok';
is $_, undef;

$r = '?';
my $t = time;
sswitch ('asdf') {
    case 'asdf' if $t % 2: { $r = 1; }
    case 'asdf' unless $t % 2: { $r = 0; }
}
is $r, $t % 2;
is $_, undef;

$r = '?';
sswitch (q))) {
    default unless $t % 2: { $r = 0; }
    default if $t % 2: { $r = 1; }
}
is $r, $t % 2;
is $_, undef;

$r = 'fail';
$r = do {
    sswitch ($words[rand @words]) {
        case $words[0]:
        case $words[1]:
        case $words[2]:
        case $words[3]: { 'ok' }
        default: { 'wtf' }
    }
};
is $r, 'ok';
is $_, undef;

$r = 'fail';
$r = do {
    sswitch ($words[rand @words]) {
        default if /^${\join '|', map { quotemeta } @words}\z/: {
            'ok'
        }
        default: {
            'wtf'
        }
    }
};
is $r, 'ok';
is $_, undef;

$r = 'fail';
{
    nswitch (1) {
        case 1: {
            $r = 'ok';
            next;
        }
        default: {
            $r = '???';
        }
    }
    $r = 'fail2';
}
is $r, 'ok';
is $_, undef;
