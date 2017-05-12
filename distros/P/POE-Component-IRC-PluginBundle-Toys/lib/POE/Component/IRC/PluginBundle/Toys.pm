package POE::Component::IRC::PluginBundle::Toys;

use strict;
use warnings;

our $VERSION = '1.001001'; # VERSION

q|
Programming is 10% science, 20% ingenuity, and 70% getting the
ingenuity to work with the science
|;

__END__

=for stopwords www.doingitwrong.com www.doingitwrong.com.

=encoding utf8

=head1 NAME

POE::Component::IRC::Plugin::Toys - a collection of fun-to-have plugins

=head1 CONTENTS

This distribution provides the following
L<POE::Component::IRC> plugins:

=over 4

=item * L<POE::Component::IRC::Plugin::AlarmClock>   IRC alarm clock

=item * L<POE::Component::IRC::Plugin::CoinFlip>    flip coins on IRC

=item * L<POE::Component::IRC::Plugin::Fortune>     fortune cookies

=item * L<POE::Component::IRC::Plugin::Magic8Ball>  Magic 8 Ball

=item * L<POE::Component::IRC::Plugin::SigFail>  make witty error/no result messages

=item * L<POE::Component::IRC::Plugin::Thanks>    make witty responses to "thank you"s

=item * L<POE::Component::IRC::Plugin::YouAreDoingItWrong> show people what they are doing wrong by giving links to
L<www.doingitwrong.com|http://www.doingitwrong.com/> images

=back

=head1 EXAMPLES

This distribution contains C<examples/> directory, with usage examples
of each plugin.

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/POE-Component-IRC-PluginBundle-Toys>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/POE-Component-IRC-PluginBundle-Toys/issues>

If you can't access GitHub, you can email your request
to C<bug-POE-Component-IRC-PluginBundle-Toys at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet <zoffix at cpan.org>
(L<http://zoffix.com/>, L<http://haslayout.net/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut