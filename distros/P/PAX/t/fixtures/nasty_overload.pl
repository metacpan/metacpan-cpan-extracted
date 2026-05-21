use strict;
use warnings;

package PAX::Fixture::Box;

use overload
    '0+' => sub { ${ $_[0] } },
    '+' => sub { ${ $_[0] } + $_[1] },
    fallback => 1;

sub new {
    my ($class, $value) = @_;
    return bless \$value, $class;
}

package main;

my $box = PAX::Fixture::Box->new(7);
die "bad overload" unless $box + 5 == 12;
1;

=pod

=head1 NAME

t/fixtures/nasty_overload.pl - fixture for fixture that stresses overload-heavy edge cases

=head1 DESCRIPTION

This fixture exists to provide fixture that stresses overload-heavy edge cases. Tests load or execute it to reproduce a
specific code shape that the PAX compiler, capture engine, or runtime must
handle correctly.

=head1 HOW TO USE

Keep the fixture small and focused on the behavior named above. When a new test
needs a different shape, add or change fixtures deliberately instead of turning
this file into a grab bag.

=cut
