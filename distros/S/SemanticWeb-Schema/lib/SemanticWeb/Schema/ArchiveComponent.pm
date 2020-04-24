use utf8;

package SemanticWeb::Schema::ArchiveComponent;

# ABSTRACT: An intangible type to be applied to any archive content

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'ArchiveComponent';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.4';


has holding_archive => (
    is        => 'rw',
    predicate => '_has_holding_archive',
    json_ld   => 'holdingArchive',
);



has item_location => (
    is        => 'rw',
    predicate => '_has_item_location',
    json_ld   => 'itemLocation',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ArchiveComponent - An intangible type to be applied to any archive content

=head1 VERSION

version v7.0.4

=head1 DESCRIPTION

An intangible type to be applied to any archive content, carrying with it a
set of properties required to describe archival items and collections.

=head1 ATTRIBUTES

=head2 C<holding_archive>

C<holdingArchive>

=for html <p><a class="localLink"
href="http://schema.org/ArchiveOrganization">ArchiveOrganization</a> that
holds, keeps or maintains the <a class="localLink"
href="http://schema.org/ArchiveComponent">ArchiveComponent</a>.<p>

A holding_archive should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ArchiveOrganization']>

=back

=head2 C<_has_holding_archive>

A predicate for the L</holding_archive> attribute.

=head2 C<item_location>

C<itemLocation>

Current location of the item.

A item_location should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=item C<InstanceOf['SemanticWeb::Schema::PostalAddress']>

=item C<Str>

=back

=head2 C<_has_item_location>

A predicate for the L</item_location> attribute.

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
