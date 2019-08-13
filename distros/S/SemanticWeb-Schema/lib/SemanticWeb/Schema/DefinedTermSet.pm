use utf8;

package SemanticWeb::Schema::DefinedTermSet;

# ABSTRACT: A set of defined terms for example a set of categories or a classification scheme

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'DefinedTermSet';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.9.0';


has has_defined_term => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'hasDefinedTerm',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::DefinedTermSet - A set of defined terms for example a set of categories or a classification scheme

=head1 VERSION

version v3.9.0

=head1 DESCRIPTION

A set of defined terms for example a set of categories or a classification
scheme, a glossary, dictionary or enumeration.

=head1 ATTRIBUTES

=head2 C<has_defined_term>

C<hasDefinedTerm>

A Defined Term contained in this term set.

A has_defined_term should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DefinedTerm']>

=back

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

This software is Copyright (c) 2018-2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
