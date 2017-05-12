package RPM::Packager::Utils;

use strict;
use warnings;

sub is_command {
    my $val = shift;
    ( $val !~ /^\d/ ) ? 1 : 0;
}

sub eval_command {
    my $cmd = shift;
    chomp( my $val = `$cmd` );
    return $val;
}

1;
