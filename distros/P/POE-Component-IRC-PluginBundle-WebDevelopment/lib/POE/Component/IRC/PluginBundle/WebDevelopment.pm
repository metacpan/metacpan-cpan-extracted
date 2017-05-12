package POE::Component::IRC::PluginBundle::WebDevelopment;

use strict;
use warnings;

our $VERSION = '2.001003'; # VERSION

q|
Programming is 10% science, 20% ingenuity, and 70% getting the
ingenuity to work with the science
|;

__END__

=for stopwords DOCTYPEs Ipsum Lorem bots html validator

=encoding utf8

=head1 NAME

POE::Component::IRC::PluginBundle::WebDevelopment - a collection of plugins useful for Web Development IRC bots

=head1 CONTENTS

This distribution provides the following
L<POE::Component::IRC> plugins:

=over 4

=item * L<POE::Component::IRC::Plugin::AntiSpamMailTo> generate C<mailto:> links that avoid dumb spam bots

=item * L<POE::Component::IRC::Plugin::BrowserSupport> lookup browser support for CSS/HTML/JS

=item * L<POE::Component::IRC::Plugin::ColorNamer> tells the name of the color by its hex code

=item * L<POE::Component::IRC::Plugin::CSS::Minifier> "minify" CSS code

=item * L<POE::Component::IRC::Plugin::CSS::PropertyInfo> lookup CSS property information

=item * L<POE::Component::IRC::Plugin::CSS::SelectorTools> couple of CSS selector tools

=item * L<POE::Component::IRC::Plugin::Google::PageRank> non-blocking access to Google's PageRank via IRC

=item * L<POE::Component::IRC::Plugin::HTML::AttributeInfo> HTML attribute info lookup

=item * L<POE::Component::IRC::Plugin::HTML::ElementInfo> lookup HTML element information

=item * L<POE::Component::IRC::Plugin::JavaScript::Minifier> PoCo::IRC plugin to minify JavaScript code

=item * L<POE::Component::IRC::Plugin::Syntax::Highlight::CSS> highlight CSS code from URIs

=item * L<POE::Component::IRC::Plugin::Syntax::Highlight::HTML> highlight HTML code from URIs

=item * L<POE::Component::IRC::Plugin::Validator::CSS> non-blocking CSS validator

=item * L<POE::Component::IRC::Plugin::Validator::HTML> non-blocking HTML validator

=item * L<POE::Component::IRC::Plugin::WWW::Alexa::TrafficRank> get Alexa traffic rank for pages

=item * L<POE::Component::IRC::Plugin::WWW::DoctypeGrabber> plugin to display DOCTYPEs and relevant information from given pages

=item * L<POE::Component::IRC::Plugin::WWW::GetPageTitle> web page title fetching IRC plugin

=item * L<POE::Component::IRC::Plugin::WWW::HTMLTagAttributeCounter> html tag and attribute counter

=item * L<POE::Component::IRC::Plugin::WWW::Lipsum> plugin to generate Lorem Ipsum text

=back

=head1 EXAMPLES

This distribution contains C<examples/> directory, with usage examples
of each plugin.

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/POE-Component-IRC-PluginBundle-WebDevelopment>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/POE-Component-IRC-PluginBundle-WebDevelopment/issues>

If you can't access GitHub, you can email your request
to C<bug-POE-Component-IRC-PluginBundle-WebDevelopment at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet <zoffix at cpan.org>
(L<http://zoffix.com/>, L<http://haslayout.net/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut