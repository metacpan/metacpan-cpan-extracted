package HybridLoad;

use strict;
use warnings;

our $LOADED = ($LOADED // 0) + 1;
our $SOURCE_FALLBACK_LOADED = 0;

sub fast_message {
    return "hybrid-fast";
}

sub slow_message {
    my ($value) = @_;
    $SOURCE_FALLBACK_LOADED = 1;
    my @parts = split /:/, ($value // '');
    return join ':', reverse @parts;
}

1;

=pod

=head1 NAME

t/fixtures/app_lib/HybridLoad.pm - fixture for fixture module used to test mixed eager and lazy load paths

=head1 DESCRIPTION

This fixture exists to provide fixture module used to test mixed eager and lazy load paths. Tests load or execute it to reproduce a
specific code shape that the PAX compiler, capture engine, or runtime must
handle correctly.

=head1 HOW TO USE

Keep the fixture small and focused on the behavior named above. When a new test
needs a different shape, add or change fixtures deliberately instead of turning
this file into a grab bag.

=cut
