use utf8;

package SemanticWeb::Schema::Language;

# ABSTRACT: Natural languages such as Spanish

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'Language';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Language - Natural languages such as Spanish

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

=for html Natural languages such as Spanish, Tamil, Hindi, English, etc. Formal
language code tags expressed in <a
href="https://en.wikipedia.org/wiki/IETF_language_tag">BCP 47</a> can be
used via the <a class="localLink"
href="http://schema.org/alternateName">alternateName</a> property. The
Language type previously also covered programming languages such as Scheme
and Lisp, which are now best represented using <a class="localLink"
href="http://schema.org/ComputerLanguage">ComputerLanguage</a>.

=head1 SEE ALSO

L<SemanticWeb::Schema::Intangible>

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
