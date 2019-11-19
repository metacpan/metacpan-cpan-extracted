use utf8;

package SemanticWeb::Schema::DefinedTerm;

# ABSTRACT: A word, name, acronym, phrase, etc

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'DefinedTerm';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v5.0.1';


has in_defined_term_set => (
    is        => 'rw',
    predicate => '_has_in_defined_term_set',
    json_ld   => 'inDefinedTermSet',
);



has term_code => (
    is        => 'rw',
    predicate => '_has_term_code',
    json_ld   => 'termCode',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::DefinedTerm - A word, name, acronym, phrase, etc

=head1 VERSION

version v5.0.1

=head1 DESCRIPTION

A word, name, acronym, phrase, etc. with a formal definition. Often used in
the context of category or subject classification, glossaries or
dictionaries, product or creative work types, etc. Use the name property
for the term being defined, use termCode if the term has an alpha-numeric
code allocated, use description to provide the definition of the term.

=head1 ATTRIBUTES

=head2 C<in_defined_term_set>

C<inDefinedTermSet>

=for html <p>A <a class="localLink"
href="http://schema.org/DefinedTermSet">DefinedTermSet</a> that contains
this term.<p>

A in_defined_term_set should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DefinedTermSet']>

=item C<Str>

=back

=head2 C<_has_in_defined_term_set>

A predicate for the L</in_defined_term_set> attribute.

=head2 C<term_code>

C<termCode>

=for html <p>A code that identifies this <a class="localLink"
href="http://schema.org/DefinedTerm">DefinedTerm</a> within a <a
class="localLink"
href="http://schema.org/DefinedTermSet">DefinedTermSet</a><p>

A term_code should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_term_code>

A predicate for the L</term_code> attribute.

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

This software is Copyright (c) 2018-2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
