package OptionTestApp::Cmd::primary::Cmd::secondary;

use strict;
use warnings;

BEGIN {
    my $moodel = $ENV{WHICH_MOODEL} || "Moo";
    eval "use $moodel;"; $@ and die $@;
    $moodel->import;
}
use MooX::Cmd;
use MooX::Options;

option sure => (
    is => "ro",
    negativable => 1,
    required => 1,
    doc => "sure?",
);

sub execute { @_ }

1;
