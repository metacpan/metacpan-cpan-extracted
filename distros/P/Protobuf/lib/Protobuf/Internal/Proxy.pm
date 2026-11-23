=encoding UTF-8

=head1 NAME

Protobuf::Internal::Proxy - Base class for tied XS objects

=head1 VERSION

version 0.14

=head1 SYNOPSIS

    package MyTiedClass;
    use parent 'Protobuf::Internal::Proxy';

    # ... implementation ...

=head1 DESCRIPTION

C<Protobuf::Internal::Proxy> is a lightweight base class providing shared
delegation helpers for Perl classes that wrap or tie Perl containers (arrays
and hashes) to underlying C<upb> XS objects.

=head1 METHODS

=head2 _xs_delegate($method, @args)

Resolves the underlying XS handle (either C<< $self->{_xs} >> for hash-based
proxies or C<$self> directly) and invokes C<$method> with C<@args>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Internal::Map>, L<Protobuf::Internal::Repeated>

=cut

package Protobuf::Internal::Proxy;

use strict;
use warnings;

# Common delegation logic for tied objects
sub _xs_delegate {
    my ($self, $method, @args) = @_;
    my $xs = ref($self) eq 'HASH' ? $self->{_xs} : $self;
    return $xs->$method(@args);
}

1;
