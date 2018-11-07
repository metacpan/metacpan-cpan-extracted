use utf8;

package SemanticWeb::Schema::DigitalDocument;

# ABSTRACT: An electronic file or document.

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'DigitalDocument';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.4';


has has_digital_document_permission => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'hasDigitalDocumentPermission',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::DigitalDocument - An electronic file or document.

=head1 VERSION

version v0.0.4

=head1 DESCRIPTION

An electronic file or document.

=head1 ATTRIBUTES

=head2 C<has_digital_document_permission>

C<hasDigitalDocumentPermission>

A permission related to the access to this document (e.g. permission to
read or write an electronic document). For a public document, specify a
grantee with an Audience with audienceType equal to "public".

A has_digital_document_permission should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DigitalDocumentPermission']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::CreativeWork>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
