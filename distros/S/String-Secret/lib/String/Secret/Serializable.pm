package String::Secret::Serializable;
use strict;
use warnings;

use parent qw/String::Secret/;

sub to_serializable { shift }

# for Storable
sub STORABLE_freeze {
    my ($self, $cloning) = @_;
    return $self->SUPER::STORABLE_freeze($cloning) if $cloning;
    return $self->unwrap;
}
sub STORABLE_thaw {
    my ($self, $cloning, $raw) = @_;
    return $self->SUPER::STORABLE_thaw(1, $raw); # force cloging to set REAL secret
}

# for JSON modules
sub TO_JSON { shift->unwrap }

# for CBOR
sub TO_CBOR { shift->unwrap }

# for JSON, CBOR, Sereal, ...
sub FREEZE {
    my ($self, $serialiser) = @_;
    return $self->unwrap;
}
sub THAW {
    my ($class, $serialiser, $raw) = @_;
    return $class->new($raw);
}

1;
__END__

=pod

=encoding utf-8

=head1 NAME

String::Secret::Serializable - serializable secret

=head1 SYNOPSIS

    use Storable;
    use String::Secret::Serializable;

    my $secret = String::Secret::Serializable->new('mysecret');
    my $freezed = Storable::nfreeze($secret); # it not masked

=head1 DESCRIPTION

TODO

=head1 SEE ALSO

L<perl>

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut
