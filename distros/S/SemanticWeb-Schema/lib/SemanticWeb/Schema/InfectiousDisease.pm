use utf8;

package SemanticWeb::Schema::InfectiousDisease;

# ABSTRACT: An infectious disease is a clinically evident human disease resulting from the presence of pathogenic microbial agents

use Moo;

extends qw/ SemanticWeb::Schema::MedicalCondition /;


use MooX::JSON_LD 'InfectiousDisease';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has infectious_agent => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'infectiousAgent',
);



has infectious_agent_class => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'infectiousAgentClass',
);



has transmission_method => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'transmissionMethod',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::InfectiousDisease - An infectious disease is a clinically evident human disease resulting from the presence of pathogenic microbial agents

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

An infectious disease is a clinically evident human disease resulting from
the presence of pathogenic microbial agents, like pathogenic viruses,
pathogenic bacteria, fungi, protozoa, multicellular parasites, and prions.
To be considered an infectious disease, such pathogens are known to be able
to cause this disease.

=head1 ATTRIBUTES

=head2 C<infectious_agent>

C<infectiousAgent>

The actual infectious agent, such as a specific bacterium.

A infectious_agent should be one of the following types:

=over

=item C<Str>

=back

=head2 C<infectious_agent_class>

C<infectiousAgentClass>

The class of infectious agent (bacteria, prion, etc.) that causes the
disease.

A infectious_agent_class should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::InfectiousAgentClass']>

=back

=head2 C<transmission_method>

C<transmissionMethod>

How the disease spreads, either as a route or vector, for example 'direct
contact', 'Aedes aegypti', etc.

A transmission_method should be one of the following types:

=over

=item C<Str>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::MedicalCondition>

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
