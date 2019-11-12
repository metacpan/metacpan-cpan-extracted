use utf8;

package SemanticWeb::Schema::Collection;

# ABSTRACT: A created collection of Creative Works or other artefacts.

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'Collection';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v5.0.0';


has collection_size => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'collectionSize',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Collection - A created collection of Creative Works or other artefacts.

=head1 VERSION

version v5.0.0

=head1 DESCRIPTION

A created collection of Creative Works or other artefacts.

=head1 ATTRIBUTES

=head2 C<collection_size>

C<collectionSize>

=for html <p>The number of items in the <a class="localLink"
href="http://schema.org/Collection">Collection</a>.<p>

A collection_size should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

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
