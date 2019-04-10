use utf8;

package SemanticWeb::Schema::BroadcastFrequencySpecification;

# ABSTRACT: The frequency in MHz and the modulation used for a particular BroadcastService.

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'BroadcastFrequencySpecification';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';


has broadcast_frequency_value => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'broadcastFrequencyValue',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::BroadcastFrequencySpecification - The frequency in MHz and the modulation used for a particular BroadcastService.

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

The frequency in MHz and the modulation used for a particular
BroadcastService.

=head1 ATTRIBUTES

=head2 C<broadcast_frequency_value>

C<broadcastFrequencyValue>

The frequency in MHz for a particular broadcast.

A broadcast_frequency_value should be one of the following types:

=over

=item C<Num>

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Intangible>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
