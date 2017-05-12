package OptionTestApp;

use strict;
use warnings;

BEGIN {
    my $moodel = $ENV{WHICH_MOODEL} || "Moo";
    eval "use $moodel;"; $@ and die $@;
    $moodel->import;
}
use MooX::Cmd execute_from_new => undef;
use MooX::Options;

option in_doubt => (
    is => "ro",
    negativable => 1,
    doc => "in doubt?",
);

sub execute { @_ }

1;
