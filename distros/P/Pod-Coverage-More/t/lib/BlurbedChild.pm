package BlurbedChild;

# A subclass of Blurbed, which overrides the hook under a comment that is no documentation,
# and double and documented under blurbs that are.

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
# @returns Num  three times the count
# @example my $nine = BlurbedChild::triple(3);
sub triple {
    my ($count) = @_;
    return $count * 3;
}

# Double a number, as the parent does, and say what it returns.
# @param   count  Num  what to double
# @returns Num  twice the count
# @example my $four = BlurbedChild::double(2);
sub double {
    my ($count) = @_;
    return $count * 2;
}

# Do nothing, as the parent does, whose POD documents it by hand.
# @example BlurbedChild::documented();
sub documented {
    return;
}

1;
