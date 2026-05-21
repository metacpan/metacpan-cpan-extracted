use strict;
use warnings;

our $AUTOLOAD;

sub AUTOLOAD {
    return "autoloaded";
}

my $code = '1 + 1';
my $result = eval "$code";
die "bad eval" unless $result == 2;
1;

=pod

=head1 NAME

t/fixtures/dynamic.pl - fixture for fixture that exercises runtime dynamic behavior during capture and compatibility tests

=head1 DESCRIPTION

This fixture exists to provide fixture that exercises runtime dynamic behavior during capture and compatibility tests. Tests load or execute it to reproduce a
specific code shape that the PAX compiler, capture engine, or runtime must
handle correctly.

=head1 HOW TO USE

Keep the fixture small and focused on the behavior named above. When a new test
needs a different shape, add or change fixtures deliberately instead of turning
this file into a grab bag.

=cut
