#!/usr/bin/perl -w
# vim: set ft=perl:

use strict;

use File::Spec;
use FindBin qw($Bin);
use Test::More;
use POSIX qw(tmpnam);
use Shell::Base;

plan tests => 2;

use_ok("Shell::Base");

my $histfile = File::Spec->catfile($Bin, "t", "history");
my $sh = Shell::Base->new(HISTFILE => $histfile);
my $wc = wc($histfile);
my $no = $sh->prompt_no;

is($no, $wc, "prompt_no returns currect history number");

sub wc {
    my $file = shift || return 0;
    my $lines = 0;
    local *WC;

    open WC, $file or return 0;
    $lines++ while (<WC>);
    close WC or return 0;

    return $lines;
}
