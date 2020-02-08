use utf8;

package SemanticWeb::Schema::StatisticalPopulation;

# ABSTRACT: A StatisticalPopulation is a set of instances of a certain given type that satisfy some set of constraints

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'StatisticalPopulation';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v6.0.1';


has constraining_property => (
    is        => 'rw',
    predicate => '_has_constraining_property',
    json_ld   => 'constrainingProperty',
);



has num_constraints => (
    is        => 'rw',
    predicate => '_has_num_constraints',
    json_ld   => 'numConstraints',
);



has population_type => (
    is        => 'rw',
    predicate => '_has_population_type',
    json_ld   => 'populationType',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::StatisticalPopulation - A StatisticalPopulation is a set of instances of a certain given type that satisfy some set of constraints

=head1 VERSION

version v6.0.1

=head1 DESCRIPTION

=for html <p>A StatisticalPopulation is a set of instances of a certain given type
that satisfy some set of constraints. The property <a class="localLink"
href="http://schema.org/populationType">populationType</a> is used to
specify the type. Any property that can be used on instances of that type
can appear on the statistical population. For example, a <a
class="localLink"
href="http://schema.org/StatisticalPopulation">StatisticalPopulation</a>
representing all <a class="localLink"
href="http://schema.org/Person">Person</a>s with a <a class="localLink"
href="http://schema.org/homeLocation">homeLocation</a> of East Podunk
California, would be described by applying the appropriate <a
class="localLink" href="http://schema.org/homeLocation">homeLocation</a>
and <a class="localLink"
href="http://schema.org/populationType">populationType</a> properties to a
<a class="localLink"
href="http://schema.org/StatisticalPopulation">StatisticalPopulation</a>
item that stands for that set of people. The properties <a
class="localLink"
href="http://schema.org/numConstraints">numConstraints</a> and <a
class="localLink"
href="http://schema.org/constrainingProperties">constrainingProperties</a>
are used to specify which of the populations properties are used to specify
the population. Note that the sense of "population" used here is the
general sense of a statistical population, and does not imply that the
population consists of people. For example, a <a class="localLink"
href="http://schema.org/populationType">populationType</a> of <a
class="localLink" href="http://schema.org/Event">Event</a> or <a
class="localLink" href="http://schema.org/NewsArticle">NewsArticle</a>
could be used. See also <a class="localLink"
href="http://schema.org/Observation">Observation</a>, and the <a
href="/docs/data-and-datasets.html">data and datasets</a> overview for more
details.<p>

=head1 ATTRIBUTES

=head2 C<constraining_property>

C<constrainingProperty>

=for html <p>Indicates a property used as a constraint to define a <a
class="localLink"
href="http://schema.org/StatisticalPopulation">StatisticalPopulation</a>
with respect to the set of entities corresponding to an indicated type (via
<a class="localLink"
href="http://schema.org/populationType">populationType</a>).<p>

A constraining_property should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=back

=head2 C<_has_constraining_property>

A predicate for the L</constraining_property> attribute.

=head2 C<num_constraints>

C<numConstraints>

=for html <p>Indicates the number of constraints (not counting <a class="localLink"
href="http://schema.org/populationType">populationType</a>) defined for a
particular <a class="localLink"
href="http://schema.org/StatisticalPopulation">StatisticalPopulation</a>.
This helps applications understand if they have access to a sufficiently
complete description of a <a class="localLink"
href="http://schema.org/StatisticalPopulation">StatisticalPopulation</a>.<p
>

A num_constraints should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=back

=head2 C<_has_num_constraints>

A predicate for the L</num_constraints> attribute.

=head2 C<population_type>

C<populationType>

=for html <p>Indicates the populationType common to all members of a <a
class="localLink"
href="http://schema.org/StatisticalPopulation">StatisticalPopulation</a>.<p
>

A population_type should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Class']>

=back

=head2 C<_has_population_type>

A predicate for the L</population_type> attribute.

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
