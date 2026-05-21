use strict;
use warnings;

BEGIN {
    package PAX::Fixture::CompilePhase;
    our $BEGIN_RAN = 1;
}

sub marker {
    return $PAX::Fixture::CompilePhase::BEGIN_RAN;
}

die "BEGIN did not run" unless marker();
1;

=pod

=head1 NAME

t/fixtures/compile_phase.pl - fixture for fixture that exercises compile-time side effects during capture

=head1 DESCRIPTION

This fixture exists to provide fixture that exercises compile-time side effects during capture. Tests load or execute it to reproduce a
specific code shape that the PAX compiler, capture engine, or runtime must
handle correctly.

=head1 HOW TO USE

Keep the fixture small and focused on the behavior named above. When a new test
needs a different shape, add or change fixtures deliberately instead of turning
this file into a grab bag.

=cut
