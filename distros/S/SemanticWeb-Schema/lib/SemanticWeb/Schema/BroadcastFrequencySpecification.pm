use utf8;

package SemanticWeb::Schema::BroadcastFrequencySpecification;

# ABSTRACT: The frequency in MHz and the modulation used for a particular BroadcastService.

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'BroadcastFrequencySpecification';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v6.0.1';


has broadcast_frequency_value => (
    is        => 'rw',
    predicate => '_has_broadcast_frequency_value',
    json_ld   => 'broadcastFrequencyValue',
);



has broadcast_signal_modulation => (
    is        => 'rw',
    predicate => '_has_broadcast_signal_modulation',
    json_ld   => 'broadcastSignalModulation',
);



has broadcast_sub_channel => (
    is        => 'rw',
    predicate => '_has_broadcast_sub_channel',
    json_ld   => 'broadcastSubChannel',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::BroadcastFrequencySpecification - The frequency in MHz and the modulation used for a particular BroadcastService.

=head1 VERSION

version v6.0.1

=head1 DESCRIPTION

The frequency in MHz and the modulation used for a particular
BroadcastService.

=head1 ATTRIBUTES

=head2 C<broadcast_frequency_value>

C<broadcastFrequencyValue>

The frequency in MHz for a particular broadcast.

A broadcast_frequency_value should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=item C<Num>

=back

=head2 C<_has_broadcast_frequency_value>

A predicate for the L</broadcast_frequency_value> attribute.

=head2 C<broadcast_signal_modulation>

C<broadcastSignalModulation>

The modulation (e.g. FM, AM, etc) used by a particular broadcast service

A broadcast_signal_modulation should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QualitativeValue']>

=item C<Str>

=back

=head2 C<_has_broadcast_signal_modulation>

A predicate for the L</broadcast_signal_modulation> attribute.

=head2 C<broadcast_sub_channel>

C<broadcastSubChannel>

The subchannel used for the broadcast.

A broadcast_sub_channel should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_broadcast_sub_channel>

A predicate for the L</broadcast_sub_channel> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::Intangible>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/SemanticWeb-Schema>
and may be cloned from L<git://github.com/robrwo/SemanticWeb-Schema.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/SemanticWeb-Schema/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2020 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
