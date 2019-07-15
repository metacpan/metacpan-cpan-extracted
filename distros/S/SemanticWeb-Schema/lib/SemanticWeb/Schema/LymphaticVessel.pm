use utf8;

package SemanticWeb::Schema::LymphaticVessel;

# ABSTRACT: A type of blood vessel that specifically carries lymph fluid unidirectionally toward the heart.

use Moo;

extends qw/ SemanticWeb::Schema::Vessel /;


use MooX::JSON_LD 'LymphaticVessel';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has originates_from => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'originatesFrom',
);



has region_drained => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'regionDrained',
);



has runs_to => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'runsTo',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::LymphaticVessel - A type of blood vessel that specifically carries lymph fluid unidirectionally toward the heart.

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

A type of blood vessel that specifically carries lymph fluid
unidirectionally toward the heart.

=head1 ATTRIBUTES

=head2 C<originates_from>

C<originatesFrom>

The vasculature the lymphatic structure originates, or afferents, from.

A originates_from should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Vessel']>

=back

=head2 C<region_drained>

C<regionDrained>

The anatomical or organ system drained by this vessel; generally refers to
a specific part of an organ.

A region_drained should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AnatomicalStructure']>

=item C<InstanceOf['SemanticWeb::Schema::AnatomicalSystem']>

=back

=head2 C<runs_to>

C<runsTo>

The vasculature the lymphatic structure runs, or efferents, to.

A runs_to should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Vessel']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Vessel>

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

This software is Copyright (c) 2018-2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
