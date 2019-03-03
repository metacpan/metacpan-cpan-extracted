package Starch::Plugin::Sereal;
use 5.008001;
use strictures 2;
our $VERSION = '0.04';

=head1 NAME

Starch::Plugin::Sereal - Use Sereal for cloning and diffing Starch data structures.

=head1 SYNOPSIS

    my $starch = Starch->new(
        plugins => ['::Sereal'],
    );

=head1 DESCRIPTION

By default L<Starch::State/clone_data> and L<Starch::State/is_data_diff>
use L<Storable> to do the heavy lifting.  This module replaces those two methods
with ones that use L<Sereal> which can be leaps and bounds faster than Storable.

In this author's testing C<is_data_diff> will be about 3x faster with Sereal and
C<clone_data> will be about 1.5x faster with Sereal.

=cut

use Sereal::Encoder;
use Sereal::Decoder;
use Types::Standard -types;

use Moo::Role;
use namespace::clean;

with 'Starch::Plugin::ForManager';

=head1 MANAGER ATTRIBUTES

These attributes are added to the L<Starch::Manager> class.

=head2 sereal_encoder

An instance of L<Sereal::Encoder>.

=cut

has sereal_encoder => (
    is  => 'lazy',
    isa => InstanceOf[ 'Sereal::Encoder' ],
);
sub _build_sereal_encoder {
    return Sereal::Encoder->new();
}

=head2 sereal_decoder

An instance of L<Sereal::Decoder>.

=cut

has sereal_decoder => (
    is  => 'lazy',
    isa => InstanceOf[ 'Sereal::Decoder' ],
);
sub _build_sereal_decoder {
    return Sereal::Decoder->new();
}

=head2 canonical_sereal_encoder

An instance of L<Sereal::Encoder> with the C<canonical> option set.

=cut

has canonical_sereal_encoder => (
    is  => 'lazy',
    isa => InstanceOf[ 'Sereal::Encoder' ],
);
sub _build_canonical_sereal_encoder {
    return Sereal::Encoder->new({ canonical => 1 });
}

=head1 MODIFIED MANAGER METHODS

These methods are added to the L<Starch::Manager> class.

=head2 clone_data

Modified to use L</sereal_encoder> and L</sereal_decoder> to clone
a data structure.

=cut

sub clone_data {
    my ($self, $data) = @_;

    return $self->sereal_decoder->decode(
        $self->sereal_encoder->encode( $data ),
    );
}

=head2 is_data_diff

Modified to use L</canonical_sereal_encoder> to encode the two data
structures.

=cut

sub is_data_diff {
    my ($self, $old, $new) = @_;

    my $encoder = $self->canonical_sereal_encoder();

    $old = $encoder->encode( $old );
    $new = $encoder->encode( $new );

    return 0 if $new eq $old;
    return 1;
}

1;
__END__

=head1 SUPPORT

Please submit bugs and feature requests to the
Starch-Plugin-Sereal GitHub issue tracker:

L<https://github.com/bluefeet/Starch-Plugin-Sereal/issues>

=head1 AUTHORS

    Aran Clary Deltac <bluefeet@gmail.com>

=head1 ACKNOWLEDGEMENTS

Thanks to L<ZipRecruiter|https://www.ziprecruiter.com/>
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

