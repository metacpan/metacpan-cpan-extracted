use utf8;

package SemanticWeb::Schema::Play;

# ABSTRACT: A play is a form of literature

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'Play';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v5.0.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Play - A play is a form of literature

=head1 VERSION

version v5.0.1

=head1 DESCRIPTION

=for html <p>A play is a form of literature, usually consisting of dialogue between
characters, intended for theatrical performance rather than just reading.
Note the peformance of a Play would be a <a class="localLink"
href="http://schema.org/TheaterEvent">TheaterEvent</a> - the <em>Play</em>
being the <a class="localLink"
href="http://schema.org/workPerformed">workPerformed</a>.<p>

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
