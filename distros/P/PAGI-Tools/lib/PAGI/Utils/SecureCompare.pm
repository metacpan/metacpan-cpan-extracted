package PAGI::Utils::SecureCompare;
$PAGI::Utils::SecureCompare::VERSION = '0.002002';
use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(secure_compare);

sub secure_compare {
    my ($a, $b) = @_;

    return 0 unless defined $a && defined $b;
    return 0 unless length($a) == length($b);

    my $result = 0;
    for my $i (0 .. length($a) - 1) {
        $result |= ord(substr($a, $i, 1)) ^ ord(substr($b, $i, 1));
    }
    return $result == 0;
}

1;

__END__

=head1 NAME

PAGI::Utils::SecureCompare - Constant-time string comparison

=head1 SYNOPSIS

    use PAGI::Utils::SecureCompare qw(secure_compare);

    if (secure_compare($submitted_token, $expected_token)) {
        ...
    }

=head1 FUNCTIONS

=head2 secure_compare($a, $b)

Compares two strings in constant time (the comparison always walks the
full length of C<$a> rather than short-circuiting on the first mismatch),
to prevent timing attacks that could otherwise leak how many leading
characters of a secret matched.

Returns false if either argument is C<undef> or if the strings differ in
length -- the length check itself is not constant-time, but length alone
does not leak the secret's content.

=head1 SEE ALSO

L<PAGI::Middleware::CSRF> and L<PAGI::Context> both use this function so
there is exactly one constant-time comparison implementation in the
distribution.

=cut
