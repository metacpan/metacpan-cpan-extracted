use utf8;

package SemanticWeb::Schema::ArchiveOrganization;

# ABSTRACT: An organization with archival holdings

use Moo;

extends qw/ SemanticWeb::Schema::LocalBusiness /;


use MooX::JSON_LD 'ArchiveOrganization';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v8.0.0';


has archive_held => (
    is        => 'rw',
    predicate => '_has_archive_held',
    json_ld   => 'archiveHeld',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ArchiveOrganization - An organization with archival holdings

=head1 VERSION

version v8.0.0

=head1 DESCRIPTION

An organization with archival holdings. An organization which keeps and
preserves archival material and typically makes it accessible to the
public.

=head1 ATTRIBUTES

=head2 C<archive_held>

C<archiveHeld>

=for html <p>Collection, <a href="https://en.wikipedia.org/wiki/Fonds">fonds</a>, or
item held, kept or maintained by an <a class="localLink"
href="http://schema.org/ArchiveOrganization">ArchiveOrganization</a>.<p>

A archive_held should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ArchiveComponent']>

=back

=head2 C<_has_archive_held>

A predicate for the L</archive_held> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::LocalBusiness>

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
