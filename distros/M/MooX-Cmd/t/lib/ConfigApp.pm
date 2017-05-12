package ConfigApp;

use strict;
use warnings;

BEGIN {
    my $moodel = $ENV{WHICH_MOODEL} || "Moo";
    eval "use $moodel;"; $@ and die $@;
    $moodel->import;
}
use MooX::Cmd with_config_from_file => 1;

has complicated_setting => (
    is => "ro",
    required => 1
);

sub execute { @_ }

1;
