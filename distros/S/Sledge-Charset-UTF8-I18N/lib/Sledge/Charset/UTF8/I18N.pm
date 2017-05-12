package Sledge::Charset::UTF8::I18N;
use strict;
use base qw(Sledge::Charset::Null);

use vars qw($VERSION);
$VERSION = '0.01';

use Encode;

sub content_type {
    return 'text/html; charset=UTF-8';
}

sub output_filter {
    my($self, $content) = @_;
    return Encode::encode("UTF-8", $content);
}


1;
__END__

=head1 NAME

Sledge::Charset::UTF8::I18N - Internationalization extension to Sledge::Charset::UTF8.

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

Sledge::Charset::UTF8::I18N is Internationalization extension to Sledge::Charset::UTF8.

=head1 AUTHOR

Yasuhiro Horiuchi E<lt>yasuhiro@hori-uchi.comE<gt>

=cut
