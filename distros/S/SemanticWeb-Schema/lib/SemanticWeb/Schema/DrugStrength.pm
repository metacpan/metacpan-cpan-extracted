use utf8;

package SemanticWeb::Schema::DrugStrength;

# ABSTRACT: A specific strength in which a medical drug is available in a specific country.

use Moo;

extends qw/ SemanticWeb::Schema::MedicalIntangible /;


use MooX::JSON_LD 'DrugStrength';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.2';


has active_ingredient => (
    is        => 'rw',
    predicate => '_has_active_ingredient',
    json_ld   => 'activeIngredient',
);



has available_in => (
    is        => 'rw',
    predicate => '_has_available_in',
    json_ld   => 'availableIn',
);



has maximum_intake => (
    is        => 'rw',
    predicate => '_has_maximum_intake',
    json_ld   => 'maximumIntake',
);



has strength_unit => (
    is        => 'rw',
    predicate => '_has_strength_unit',
    json_ld   => 'strengthUnit',
);



has strength_value => (
    is        => 'rw',
    predicate => '_has_strength_value',
    json_ld   => 'strengthValue',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::DrugStrength - A specific strength in which a medical drug is available in a specific country.

=head1 VERSION

version v7.0.2

=head1 DESCRIPTION

A specific strength in which a medical drug is available in a specific
country.

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

=head2 C<available_in>

C<availableIn>

The location in which the strength is available.

A available_in should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AdministrativeArea']>

=back

=head2 C<_has_available_in>

A predicate for the L</available_in> attribute.

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

=head2 C<strength_unit>

C<strengthUnit>

The units of an active ingredient's strength, e.g. mg.

A strength_unit should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_strength_unit>

A predicate for the L</strength_unit> attribute.

=head2 C<strength_value>

C<strengthValue>

The value of an active ingredient's strength, e.g. 325.

A strength_value should be one of the following types:

=over

=item C<Num>

=back

=head2 C<_has_strength_value>

A predicate for the L</strength_value> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::MedicalIntangible>

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
