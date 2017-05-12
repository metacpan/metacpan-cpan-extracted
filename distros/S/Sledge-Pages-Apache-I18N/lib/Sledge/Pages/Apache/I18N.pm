package Sledge::Pages::Apache::I18N;
use strict;
use base qw(Sledge::Pages::Base);

use vars qw($VERSION);
$VERSION = '0.02';

use Apache;
use Sledge::Request::Apache::I18N;

sub create_request {
    my($self, $r) = @_;
    return Sledge::Request::Apache::I18N->new($r || Apache->request);
}

1;

__END__

=head1 NAME

Sledge::Pages::Apache::I18N - Internationalization extension to Sledge::Pages::Apache

=head1 SYNOPSIS

  package YourProj::Pages;
  use strict;
  use base qw(Sledge::Pages::Apache::I18N);
  use Sledge::Template::TT::I18N;
  use Sledge::Charset::UTF8::I18N;

  ....

  sub create_charset {
      my $self = shift;
      Sledge::Charset::UTF8::I18N->new($self);
  }

=head1 DESCRIPTION

Sledge::Pages::Apache::I18N is Internationalization extension to Sledge::Pages::Apache.

=head1 AUTHOR

Yasuhiro Horiuchi E<lt>yasuhiro@hori-uchi.comE<gt>

=head1 SEE ALSO

L<Sledge::Pages::Apache>, L<Apache::Request::I18N>

=cut
