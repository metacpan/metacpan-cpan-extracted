package ResidualOnly;

use strict;
use warnings;

sub reverse_words {
    my ($text) = @_;
    my @parts = split /\s+/, ($text // '');
    return join ' ', reverse @parts;
}

1;

=pod

=head1 NAME

t/fixtures/app_lib/ResidualOnly.pm - fixture for fixture module used to test residual runtime-only paths

=head1 DESCRIPTION

This fixture exists to provide fixture module used to test residual runtime-only paths. Tests load or execute it to reproduce a
specific code shape that the PAX compiler, capture engine, or runtime must
handle correctly.

=head1 HOW TO USE

Keep the fixture small and focused on the behavior named above. When a new test
needs a different shape, add or change fixtures deliberately instead of turning
this file into a grab bag.

=cut
