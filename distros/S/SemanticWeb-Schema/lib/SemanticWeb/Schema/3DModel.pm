use utf8;

package SemanticWeb::Schema::3DModel;

# ABSTRACT: A 3D model represents some kind of 3D content

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD '3DModel';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.9.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::3DModel - A 3D model represents some kind of 3D content

=head1 VERSION

version v3.9.0

=head1 DESCRIPTION

=for html A 3D model represents some kind of 3D content, which may have <a
class="localLink" href="http://schema.org/encoding">encoding</a>s in one or
more <a class="localLink"
href="http://schema.org/MediaObject">MediaObject</a>s. Many 3D formats are
available (e.g. see <a
href="https://en.wikipedia.org/wiki/Category:3D_graphics_file_formats">Wiki
pedia</a>); specific encoding formats can be represented using the <a
class="localLink"
href="http://schema.org/encodingFormat">encodingFormat</a> property applied
to the relevant <a class="localLink"
href="http://schema.org/MediaObject">MediaObject</a>. For the case of a
single file published after Zip compression, the convention of appending
'+zip' to the <a class="localLink"
href="http://schema.org/encodingFormat">encodingFormat</a> can be used.
Geospatial, AR/VR, artistic/animation, gaming, engineering and scientific
content can all be represented using <a class="localLink"
href="http://schema.org/3DModel">3DModel</a>.

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
