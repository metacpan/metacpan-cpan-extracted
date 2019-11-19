use utf8;

package SemanticWeb::Schema::SatiricalArticle;

# ABSTRACT: An Article whose content is primarily [satirical] in nature

use Moo;

extends qw/ SemanticWeb::Schema::Article /;


use MooX::JSON_LD 'SatiricalArticle';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v5.0.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::SatiricalArticle - An Article whose content is primarily [satirical] in nature

=head1 VERSION

version v5.0.1

=head1 DESCRIPTION

=for html <p>An <a class="localLink" href="http://schema.org/Article">Article</a>
whose content is primarily <a
href="https://en.wikipedia.org/wiki/Satire">[satirical]</a> in nature, i.e.
unlikely to be literally true. A satirical article is sometimes but not
necessarily also a <a class="localLink"
href="http://schema.org/NewsArticle">NewsArticle</a>. <a class="localLink"
href="http://schema.org/ScholarlyArticle">ScholarlyArticle</a>s are also
sometimes satirized.<p>

=head1 SEE ALSO

L<SemanticWeb::Schema::Article>

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
