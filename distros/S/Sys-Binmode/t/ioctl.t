#!/usr/bin/env perl

use strict;
use warnings;

use Sys::Binmode;

use Test::More;
use Test::FailWarnings;

plan skip_all => "Only for Linux, not $^O" if $^O ne 'linux';

eval { require IO::Pty } or plan skip_all => "No IO::Pty ($@)";

# cf. ioctl_list(4)
use constant {
    TIOCGWINSZ => 0x00005413,
    TIOCSWINSZ => 0x00005414,
};

my $pack_tmpl = 'S!4';
my $empty = pack $pack_tmpl;

my $packed = pack $pack_tmpl, (255) x 4;
utf8::upgrade $packed;

my $pty = IO::Pty->new();
ioctl $pty, TIOCSWINSZ, $packed;
substr($packed, length $empty) = q<>;

my $val = $empty;
ioctl $pty, TIOCGWINSZ, $val;

substr($val, length $empty) = q<>;

is( $val, $packed, 'ioctl downgraded its argument') or do {
        diag sprintf 'got: %v.02x', $val;
        diag sprintf 'wanted: %v.02x', $packed;
};

done_testing();
