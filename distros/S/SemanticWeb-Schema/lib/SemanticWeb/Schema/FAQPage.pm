use utf8;

package SemanticWeb::Schema::FAQPage;

# ABSTRACT: A <a class="localLink" href="http://schema

use Moo;

extends qw/ SemanticWeb::Schema::WebPage /;


use MooX::JSON_LD 'FAQPage';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::FAQPage - A <a class="localLink" href="http://schema

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

=for html A <a class="localLink" href="http://schema.org/FAQPage">FAQPage</a> is a <a
class="localLink" href="http://schema.org/WebPage">WebPage</a> presenting
one or more "<a href="https://en.wikipedia.org/wiki/FAQ">Frequently asked
questions</a>" (see also <a class="localLink"
href="http://schema.org/QAPage">QAPage</a>).

=head1 SEE ALSO

L<SemanticWeb::Schema::WebPage>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
