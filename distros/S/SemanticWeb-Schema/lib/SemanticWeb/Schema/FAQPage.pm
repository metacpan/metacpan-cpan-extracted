use utf8;

package SemanticWeb::Schema::FAQPage;

# ABSTRACT: A FAQPage is a WebPage presenting one or more " Frequently asked questions " (see also QAPage ).

use Moo;

extends qw/ SemanticWeb::Schema::WebPage /;


use MooX::JSON_LD 'FAQPage';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v9.0.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::FAQPage - A FAQPage is a WebPage presenting one or more " Frequently asked questions " (see also QAPage ).

=head1 VERSION

version v9.0.0

=head1 DESCRIPTION

=for html <p>A <a class="localLink" href="http://schema.org/FAQPage">FAQPage</a> is a
<a class="localLink" href="http://schema.org/WebPage">WebPage</a>
presenting one or more "<a
href="https://en.wikipedia.org/wiki/FAQ">Frequently asked questions</a>"
(see also <a class="localLink"
href="http://schema.org/QAPage">QAPage</a>).<p>

=head1 SEE ALSO

L<SemanticWeb::Schema::WebPage>

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
