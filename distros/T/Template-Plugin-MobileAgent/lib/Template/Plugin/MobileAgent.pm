package Template::Plugin::MobileAgent;

use strict;
use vars qw($VERSION);
$VERSION = 0.01;

require Template::Plugin;
use base qw(Template::Plugin);

use HTTP::MobileAgent;

sub new {
    my $class = shift;
    my $context = shift;
    return HTTP::MobileAgent->new(@_);
}

1;
__END__

=head1 NAME

Template::Plugin::MobileAgent - TT interface for HTTP::MobileAgent

=head1 SYNOPSIS

  [% USE ua = MobileAgent %]
  <img src="logo.[% ua.is_docomo ? 'gif' : 'png' %]">

=head1 DESCRIPTION

Template::Plugin::MobileAgent is a TT plugin for
HTTP::MobileAgent. See L<HTTP::MobileAgent> and its subclasses for
available methods.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::MobileAgent>, L<Template>

=cut
