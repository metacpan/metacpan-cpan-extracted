package Sledge::Plugin::ShowText;
use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.03';

sub import {
    my $class = shift;
    my $pkg   = caller(0);

    no strict 'refs';
    *{"$pkg\::show_text"}    = \&show_text;
}

sub show_text {
    my $self         = shift;
    my $content      = shift;

    $self->r->header_out('Pragma'        => 'no-cache');
    $self->r->header_out('Cache-Control' => 'no-cache');

    $self->r->content_type("text/plain");
    $self->set_content_length(length $content);
    $self->send_http_header;
    $self->r->print($content);
    $self->invoke_hook('AFTER_OUTPUT');
    $self->finished(1);    
}

1;
__END__

=head1 NAME

Sledge::Plugin::ShowText - plugin to show text from data

=head1 SYNOPSIS

  package Your::Pages;
  use Sledge::Plugin::ShowText;
  use Your::Data;

  sub dispatch_foo {
      my $self  = shift;
      my $id    = $self->r->param('id');
      my $text = Your::Data->retrieve($id)->text;
      return $self->show_text($text);
  }

  sub dispatch_bar {
      my $self  = shift;

      if (.....) {
          return $self->show_text('ok');
      }
      else {
          return $self->show_text('ng');
      }
  }

=head1 DESCRIPTION

Sledge::Plugin::ShowText is show text Plugin for Sledge. You can easy to generate  plain text.

=head1 AUTHOR

KIMURA, takefumi E<lt>takefumi@mobilefactory.jpE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Slege::Plugin::ShowImage>

=cut
