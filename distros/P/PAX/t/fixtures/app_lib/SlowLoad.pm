package SlowLoad;

use strict;
use warnings;

our $LOADED = ($LOADED // 0) + 1;

sub message {
    return "slowload-ready";
}

1;

=pod

=head1 NAME

t/fixtures/app_lib/SlowLoad.pm - fixture for fixture module used to test slow compile/load behavior

=head1 DESCRIPTION

This fixture exists to provide fixture module used to test slow compile/load behavior. Tests load or execute it to reproduce a
specific code shape that the PAX compiler, capture engine, or runtime must
handle correctly.

=head1 HOW TO USE

Keep the fixture small and focused on the behavior named above. When a new test
needs a different shape, add or change fixtures deliberately instead of turning
this file into a grab bag.

=cut
