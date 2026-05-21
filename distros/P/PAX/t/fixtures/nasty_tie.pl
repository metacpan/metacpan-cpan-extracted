use strict;
use warnings;

package PAX::Fixture::TieScalar;

sub TIESCALAR {
    my ($class, $value) = @_;
    return bless \$value, $class;
}

sub FETCH {
    my ($self) = @_;
    return $$self;
}

sub STORE {
    my ($self, $value) = @_;
    $$self = $value;
}

package main;

tie my $value, 'PAX::Fixture::TieScalar', 10;
$value = $value + 5;
die "bad tie" unless $value == 15;
1;

=pod

=head1 NAME

t/fixtures/nasty_tie.pl - fixture for fixture that stresses tied-variable edge cases

=head1 DESCRIPTION

This fixture exists to provide fixture that stresses tied-variable edge cases. Tests load or execute it to reproduce a
specific code shape that the PAX compiler, capture engine, or runtime must
handle correctly.

=head1 HOW TO USE

Keep the fixture small and focused on the behavior named above. When a new test
needs a different shape, add or change fixtures deliberately instead of turning
this file into a grab bag.

=cut
