use utf8;

package SemanticWeb::Schema::ProductCollection;

# ABSTRACT: A set of products (either ProductGroup s or specific variants) that are listed together e

use Moo;

extends qw/ SemanticWeb::Schema::Collection SemanticWeb::Schema::Product /;


use MooX::JSON_LD 'ProductCollection';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v9.0.0';


has includes_object => (
    is        => 'rw',
    predicate => '_has_includes_object',
    json_ld   => 'includesObject',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ProductCollection - A set of products (either ProductGroup s or specific variants) that are listed together e

=head1 VERSION

version v9.0.0

=head1 DESCRIPTION

=for html <p>A set of products (either <a class="localLink"
href="http://schema.org/ProductGroup">ProductGroup</a>s or specific
variants) that are listed together e.g. in an <a class="localLink"
href="http://schema.org/Offer">Offer</a>.<p>

=head1 ATTRIBUTES

=head2 C<includes_object>

C<includesObject>

=for html <p>This links to a node or nodes indicating the exact quantity of the
products included in an <a class="localLink"
href="http://schema.org/Offer">Offer</a> or <a class="localLink"
href="http://schema.org/ProductCollection">ProductCollection</a>.<p>

A includes_object should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::TypeAndQuantityNode']>

=back

=head2 C<_has_includes_object>

A predicate for the L</includes_object> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::Product>

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
