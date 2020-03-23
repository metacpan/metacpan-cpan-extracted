use utf8;

package SemanticWeb::Schema::SportsTeam;

# ABSTRACT: Organization: Sports team.

use Moo;

extends qw/ SemanticWeb::Schema::SportsOrganization /;


use MooX::JSON_LD 'SportsTeam';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.0';


has athlete => (
    is        => 'rw',
    predicate => '_has_athlete',
    json_ld   => 'athlete',
);



has coach => (
    is        => 'rw',
    predicate => '_has_coach',
    json_ld   => 'coach',
);



has gender => (
    is        => 'rw',
    predicate => '_has_gender',
    json_ld   => 'gender',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::SportsTeam - Organization: Sports team.

=head1 VERSION

version v7.0.0

=head1 DESCRIPTION

Organization: Sports team.

=head1 ATTRIBUTES

=head2 C<athlete>

A person that acts as performing member of a sports team; a player as
opposed to a coach.

A athlete should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_athlete>

A predicate for the L</athlete> attribute.

=head2 C<coach>

A person that acts in a coaching role for a sports team.

A coach should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_coach>

A predicate for the L</coach> attribute.

=head2 C<gender>

=for html <p>Gender of something, typically a <a class="localLink"
href="http://schema.org/Person">Person</a>, but possibly also fictional
characters, animals, etc. While http://schema.org/Male and
http://schema.org/Female may be used, text strings are also acceptable for
people who do not identify as a binary gender. The <a class="localLink"
href="http://schema.org/gender">gender</a> property can also be used in an
extended sense to cover e.g. the gender of sports teams. As with the gender
of individuals, we do not try to enumerate all possibilities. A
mixed-gender <a class="localLink"
href="http://schema.org/SportsTeam">SportsTeam</a> can be indicated with a
text value of "Mixed".<p>

A gender should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::GenderType']>

=item C<Str>

=back

=head2 C<_has_gender>

A predicate for the L</gender> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::SportsOrganization>

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
