use utf8;

package SemanticWeb::Schema::Substance;

# ABSTRACT: Any matter of defined composition that has discrete existence

use Moo;

extends qw/ SemanticWeb::Schema::MedicalEntity /;


use MooX::JSON_LD 'Substance';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v9.0.0';


has active_ingredient => (
    is        => 'rw',
    predicate => '_has_active_ingredient',
    json_ld   => 'activeIngredient',
);



has maximum_intake => (
    is        => 'rw',
    predicate => '_has_maximum_intake',
    json_ld   => 'maximumIntake',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Substance - Any matter of defined composition that has discrete existence

=head1 VERSION

version v9.0.0

=head1 DESCRIPTION

Any matter of defined composition that has discrete existence, whose origin
may be biological, mineral or chemical.

=head1 ATTRIBUTES

=head2 C<active_ingredient>

C<activeIngredient>

An active ingredient, typically chemical compounds and/or biologic
substances.

A active_ingredient should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_active_ingredient>

A predicate for the L</active_ingredient> attribute.

=head2 C<maximum_intake>

C<maximumIntake>

Recommended intake of this supplement for a given population as defined by
a specific recommending authority.

A maximum_intake should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MaximumDoseSchedule']>

=back

=head2 C<_has_maximum_intake>

A predicate for the L</maximum_intake> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::MedicalEntity>

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
