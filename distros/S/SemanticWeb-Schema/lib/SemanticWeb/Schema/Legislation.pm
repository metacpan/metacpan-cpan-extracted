use utf8;

package SemanticWeb::Schema::Legislation;

# ABSTRACT: A legal document such as an act

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'Legislation';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.4';


has jurisdiction => (
    is        => 'rw',
    predicate => '_has_jurisdiction',
    json_ld   => 'jurisdiction',
);



has legislation_applies => (
    is        => 'rw',
    predicate => '_has_legislation_applies',
    json_ld   => 'legislationApplies',
);



has legislation_changes => (
    is        => 'rw',
    predicate => '_has_legislation_changes',
    json_ld   => 'legislationChanges',
);



has legislation_consolidates => (
    is        => 'rw',
    predicate => '_has_legislation_consolidates',
    json_ld   => 'legislationConsolidates',
);



has legislation_date => (
    is        => 'rw',
    predicate => '_has_legislation_date',
    json_ld   => 'legislationDate',
);



has legislation_date_version => (
    is        => 'rw',
    predicate => '_has_legislation_date_version',
    json_ld   => 'legislationDateVersion',
);



has legislation_identifier => (
    is        => 'rw',
    predicate => '_has_legislation_identifier',
    json_ld   => 'legislationIdentifier',
);



has legislation_jurisdiction => (
    is        => 'rw',
    predicate => '_has_legislation_jurisdiction',
    json_ld   => 'legislationJurisdiction',
);



has legislation_legal_force => (
    is        => 'rw',
    predicate => '_has_legislation_legal_force',
    json_ld   => 'legislationLegalForce',
);



has legislation_passed_by => (
    is        => 'rw',
    predicate => '_has_legislation_passed_by',
    json_ld   => 'legislationPassedBy',
);



has legislation_responsible => (
    is        => 'rw',
    predicate => '_has_legislation_responsible',
    json_ld   => 'legislationResponsible',
);



has legislation_transposes => (
    is        => 'rw',
    predicate => '_has_legislation_transposes',
    json_ld   => 'legislationTransposes',
);



has legislation_type => (
    is        => 'rw',
    predicate => '_has_legislation_type',
    json_ld   => 'legislationType',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Legislation - A legal document such as an act

=head1 VERSION

version v7.0.4

=head1 DESCRIPTION

A legal document such as an act, decree, bill, etc. (enforceable or not) or
a component of a legal act (like an article).

=head1 ATTRIBUTES

=head2 C<jurisdiction>

Indicates a legal jurisdiction, e.g. of some legislation, or where some
government service is based.

A jurisdiction should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AdministrativeArea']>

=item C<Str>

=back

=head2 C<_has_jurisdiction>

A predicate for the L</jurisdiction> attribute.

=head2 C<legislation_applies>

C<legislationApplies>

=for html <p>Indicates that this legislation (or part of a legislation) somehow
transfers another legislation in a different legislative context. This is
an informative link, and it has no legal value. For legally-binding links
of transposition, use the <a
href="/legislationTransposes">legislationTransposes</a> property. For
example an informative consolidated law of a European Union's member state
"applies" the consolidated version of the European Directive implemented in
it.<p>

A legislation_applies should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Legislation']>

=back

=head2 C<_has_legislation_applies>

A predicate for the L</legislation_applies> attribute.

=head2 C<legislation_changes>

C<legislationChanges>

=for html <p>Another legislation that this legislation changes. This encompasses the
notions of amendment, replacement, correction, repeal, or other types of
change. This may be a direct change (textual or non-textual amendment) or a
consequential or indirect change. The property is to be used to express the
existence of a change relationship between two acts rather than the
existence of a consolidated version of the text that shows the result of
the change. For consolidation relationships, use the <a
href="/legislationConsolidates">legislationConsolidates</a> property.<p>

A legislation_changes should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Legislation']>

=back

=head2 C<_has_legislation_changes>

A predicate for the L</legislation_changes> attribute.

=head2 C<legislation_consolidates>

C<legislationConsolidates>

Indicates another legislation taken into account in this consolidated
legislation (which is usually the product of an editorial process that
revises the legislation). This property should be used multiple times to
refer to both the original version or the previous consolidated version,
and to the legislations making the change.

A legislation_consolidates should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Legislation']>

=back

=head2 C<_has_legislation_consolidates>

A predicate for the L</legislation_consolidates> attribute.

=head2 C<legislation_date>

C<legislationDate>

The date of adoption or signature of the legislation. This is the date at
which the text is officially aknowledged to be a legislation, even though
it might not even be published or in force.

A legislation_date should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_legislation_date>

A predicate for the L</legislation_date> attribute.

=head2 C<legislation_date_version>

C<legislationDateVersion>

The point-in-time at which the provided description of the legislation is
valid (e.g. : when looking at the law on the 2016-04-07 (= dateVersion), I
get the consolidation of 2015-04-12 of the "National Insurance
Contributions Act 2015")

A legislation_date_version should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_legislation_date_version>

A predicate for the L</legislation_date_version> attribute.

=head2 C<legislation_identifier>

C<legislationIdentifier>

An identifier for the legislation. This can be either a string-based
identifier, like the CELEX at EU level or the NOR in France, or a
web-based, URL/URI identifier, like an ELI (European Legislation
Identifier) or an URN-Lex.

A legislation_identifier should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_legislation_identifier>

A predicate for the L</legislation_identifier> attribute.

=head2 C<legislation_jurisdiction>

C<legislationJurisdiction>

The jurisdiction from which the legislation originates.

A legislation_jurisdiction should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AdministrativeArea']>

=item C<Str>

=back

=head2 C<_has_legislation_jurisdiction>

A predicate for the L</legislation_jurisdiction> attribute.

=head2 C<legislation_legal_force>

C<legislationLegalForce>

Whether the legislation is currently in force, not in force, or partially
in force.

A legislation_legal_force should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::LegalForceStatus']>

=back

=head2 C<_has_legislation_legal_force>

A predicate for the L</legislation_legal_force> attribute.

=head2 C<legislation_passed_by>

C<legislationPassedBy>

The person or organization that originally passed or made the law :
typically parliament (for primary legislation) or government (for secondary
legislation). This indicates the "legal author" of the law, as opposed to
its physical author.

A legislation_passed_by should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_legislation_passed_by>

A predicate for the L</legislation_passed_by> attribute.

=head2 C<legislation_responsible>

C<legislationResponsible>

An individual or organization that has some kind of responsibility for the
legislation. Typically the ministry who is/was in charge of elaborating the
legislation, or the adressee for potential questions about the legislation
once it is published.

A legislation_responsible should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_legislation_responsible>

A predicate for the L</legislation_responsible> attribute.

=head2 C<legislation_transposes>

C<legislationTransposes>

Indicates that this legislation (or part of legislation) fulfills the
objectives set by another legislation, by passing appropriate
implementation measures. Typically, some legislations of European Union's
member states or regions transpose European Directives. This indicates a
legally binding link between the 2 legislations.

A legislation_transposes should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Legislation']>

=back

=head2 C<_has_legislation_transposes>

A predicate for the L</legislation_transposes> attribute.

=head2 C<legislation_type>

C<legislationType>

The type of the legislation. Examples of values are "law", "act",
"directive", "decree", "regulation", "statutory instrument", "loi
organique", "rÃ¨glement grand-ducal", etc., depending on the country.

A legislation_type should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CategoryCode']>

=item C<Str>

=back

=head2 C<_has_legislation_type>

A predicate for the L</legislation_type> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::CreativeWork>

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
