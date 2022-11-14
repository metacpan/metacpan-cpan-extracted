package Myriad::Util::Secret;

use strict;
use warnings;

our $VERSION = '1.001'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

=head1 Name

Myriad::Util::Secret - protect secrets from getting exposed accidentally

=head1 SYNOPSIS

    my $secret = Myriad::Util::Secret->new('shh.. secret!');

=head1 DESCRIPTION

When stringified, this will return C<***> instead of the real data.

=cut

use overload
    q{""} => sub { "***" },
    eq => 'equal',
    ne => 'not_equal',
    fallback => 1;

use Scalar::Util qw(blessed);

# Actual secret values are stored here, so that Dumper() doesn't expose them
my %secrets;

sub new {
    my ($class, $value) = @_;
    die 'need secret value' unless defined $value;
    my $self = bless \(my $placeholder), $class;
    $secrets{$self} = $value;
    return $self;
}

=head2 not_equal

Returns true if the secret value does not match the provided value.

=cut

sub not_equal {
    my ($self, $other) = @_;
    return !$self->equal($other);
}

=head2 equal

Returns true if the secret value matches the provided value.

=cut

sub equal {
    my ($self, $other) = @_;
    return 0 unless defined $other;

    if(blessed($other) and $other->isa('Myriad::Util::Secret')) {
        return $other->equal($self->secret_value);
    }

    my $comparison = $secrets{$self} // '';

    # Simple stepwise logic here - we start by assuming that the values _do_ match
    my $match = 1;

    # ... then we loop through the characters of the provided string, and we
    # mark as not matching if any of those characters don't match
    no warnings 'substr'; # substr out of string returns undef...
    no warnings 'uninitialized'; # ... so we expect and don't care for mismatched lengths
    for my $idx (0..length($other)) {
        $match = 0 if substr($other, $idx, 1) ne substr($comparison, $idx, 1);
    }
    # At this point, $match is true if the characters in the provided string match
    # the equivalent characters in the real string - but that's not good enough,
    # we need to confirm that _all_ characters were compared
    $match = 0 unless length($comparison) == length($other);

    return $match;
}

=head2 secret_value

Returns the original secret value as text.

=cut

sub secret_value {
    my ($self) = @_;
    return '' . $secrets{$self}
}

sub DESTROY {
    my ($self) = @_;
    return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
    delete $secrets{$self}
}

1;

__END__

=head1 SEE ALSO

=over 4

=item * L<String::Compare::ConstantTime> - handles the constant-time comparison, but returns
early if the string lengths are different, which is problematic since knowing the length makes
attacks easier

=back

=head1 AUTHOR

Deriv Group Services Ltd. C<< DERIV@cpan.org >>.

See L<Myriad/CONTRIBUTORS> for full details.

=head1 LICENSE

Copyright Deriv Group Services Ltd 2020-2022. Licensed under the same terms as Perl itself.

