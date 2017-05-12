package OptionTestApp::Cmd::primary;

use strict;
use warnings;

BEGIN {
    my $moodel = $ENV{WHICH_MOODEL} || "Moo";
    eval "use $moodel;"; $@ and die $@;
    $moodel->import;
}
use MooX::Cmd;
use MooX::Options;

option serious => (
    is => "ro",
    negativable => 1,
    required => 0,
    doc => "serious?",
);

sub execute { @_ }

1;
