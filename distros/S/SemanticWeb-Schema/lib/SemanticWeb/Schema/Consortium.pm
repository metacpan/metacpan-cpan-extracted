use utf8;

package SemanticWeb::Schema::Consortium;

# ABSTRACT: A Consortium is a membership Organization whose members are typically Organizations.

use Moo;

extends qw/ SemanticWeb::Schema::Organization /;


use MooX::JSON_LD 'Consortium';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v9.0.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Consortium - A Consortium is a membership Organization whose members are typically Organizations.

=head1 VERSION

version v9.0.0

=head1 DESCRIPTION

=for html <p>A Consortium is a membership <a class="localLink"
href="http://schema.org/Organization">Organization</a> whose members are
typically Organizations.<p>

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
