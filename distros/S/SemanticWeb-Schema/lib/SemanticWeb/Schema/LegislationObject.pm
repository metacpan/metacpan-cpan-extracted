use utf8;

package SemanticWeb::Schema::LegislationObject;

# ABSTRACT: A specific object or file containing a Legislation

use Moo;

extends qw/ SemanticWeb::Schema::Legislation SemanticWeb::Schema::MediaObject /;


use MooX::JSON_LD 'LegislationObject';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.3';


has legislation_legal_value => (
    is        => 'rw',
    predicate => '_has_legislation_legal_value',
    json_ld   => 'legislationLegalValue',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::LegislationObject - A specific object or file containing a Legislation

=head1 VERSION

version v7.0.3

=head1 DESCRIPTION

A specific object or file containing a Legislation. Note that the same
Legislation can be published in multiple files. For example, a digitally
signed PDF, a plain PDF and an HTML version.

=head1 ATTRIBUTES

=head2 C<legislation_legal_value>

C<legislationLegalValue>

The legal value of this legislation file. The same legislation can be
written in multiple files with different legal values. Typically a
digitally signed PDF have a "stronger" legal value than the HTML file of
the same act.

A legislation_legal_value should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::LegalValueLevel']>

=back

=head2 C<_has_legislation_legal_value>

A predicate for the L</legislation_legal_value> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::MediaObject>

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
