#!/usr/bin/perl -w
# vim: set ft=perl:

use strict;

use File::Spec::Functions qw(catfile);
use FindBin qw($Bin);
use Test::More;
use POSIX qw(tmpnam);
use Shell::Base;

plan tests => 3;

use_ok("Shell::Base");

my $histfile = -d "t" ? catfile($Bin, "t", "history")
                      : catfile($Bin, "history");
my $sh = Shell::Base->new(HISTFILE => $histfile);

is(ref $sh->term->Attribs->{completion_function},
    'CODE', "completion_function defined");

# If history is enabled, then the history_length attribute will
# be set.

is($sh->term->{'history_length'}, wc($histfile), 
    "history file was loaded correctly");

sub wc {
    my $file = shift || return 0;
    my $lines = 0;
    local *WC;

    open WC, $file or return 0;
    $lines++ while (<WC>);
    close WC or return 0;

    return $lines;
}
