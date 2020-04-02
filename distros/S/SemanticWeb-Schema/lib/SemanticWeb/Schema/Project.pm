use utf8;

package SemanticWeb::Schema::Project;

# ABSTRACT: An enterprise (potentially individual but typically collaborative)

use Moo;

extends qw/ SemanticWeb::Schema::Organization /;


use MooX::JSON_LD 'Project';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.2';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Project - An enterprise (potentially individual but typically collaborative)

=head1 VERSION

version v7.0.2

=head1 DESCRIPTION

=for html <p>An enterprise (potentially individual but typically collaborative),
planned to achieve a particular aim. Use properties from <a
class="localLink" href="http://schema.org/Organization">Organization</a>,
<a class="localLink"
href="http://schema.org/subOrganization">subOrganization</a>/<a
class="localLink"
href="http://schema.org/parentOrganization">parentOrganization</a> to
indicate project sub-structures.<p>

=head1 SEE ALSO

L<SemanticWeb::Schema::Organization>

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
