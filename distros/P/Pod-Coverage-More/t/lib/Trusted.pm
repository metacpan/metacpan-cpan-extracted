package Trusted;

# A module whose POD documents one sub and trusts the other two, as Pod::Coverage::TrustPod reads it.

use 5.036;
use warnings FATAL => q{all};

=head1 FUNCTIONS

=head2 double(count)

=over 4

=item count - Num - what to double

=back

Returns Num.

    my $four = Trusted::double(2);

=for Pod::Coverage BUILD

=begin Pod::Coverage

  triple

=end Pod::Coverage

=cut

sub double {
    my ($count) = @_;
    return $count * 2;
}

sub BUILD {
    return;
}

sub triple {
    my ($count) = @_;
    return $count * 3;
}

1;
