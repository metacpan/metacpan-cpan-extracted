package BlurbedChild;

# A subclass of Blurbed, which overrides the hook under a comment that is no documentation.

use 5.036;
use warnings FATAL => q{all};

use parent -norequire, 'Blurbed';

# The record is marked, for the test.
sub hook {
    my ( $self, $record ) = @_;
    $record->{seen} = 1;
    return;
}

# Triple a number.
# @param   count  Num  what to triple
# @example my $nine = BlurbedChild::triple(3);
sub triple {
    my ($count) = @_;
    return $count * 3;
}

1;
