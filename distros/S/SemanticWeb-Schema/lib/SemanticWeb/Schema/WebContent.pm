use utf8;

package SemanticWeb::Schema::WebContent;

# ABSTRACT: WebContent is a type representing all WebPage 

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'WebContent';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v8.0.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::WebContent - WebContent is a type representing all WebPage 

=head1 VERSION

version v8.0.0

=head1 DESCRIPTION

=for html <p>WebContent is a type representing all <a class="localLink"
href="http://schema.org/WebPage">WebPage</a>, <a class="localLink"
href="http://schema.org/WebSite">WebSite</a> and <a class="localLink"
href="http://schema.org/WebPageElement">WebPageElement</a> content. It is
sometimes the case that detailed distinctions between Web pages, sites and
their parts is not always important or obvious. The <a class="localLink"
href="http://schema.org/WebContent">WebContent</a> type makes it easier to
describe Web-addressable content without requiring such distinctions to
always be stated. (The intent is that the existing types <a
class="localLink" href="http://schema.org/WebPage">WebPage</a>, <a
class="localLink" href="http://schema.org/WebSite">WebSite</a> and <a
class="localLink"
href="http://schema.org/WebPageElement">WebPageElement</a> will eventually
be declared as subtypes of <a class="localLink"
href="http://schema.org/WebContent">WebContent</a>.)<p>

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
