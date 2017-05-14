package Mojolicious::Plugin::LinkEmbedder::Link::Text::Metacpan;

=head1 NAME

Mojolicious::Plugin::LinkEmbedder::Link::Text::Metacpan - metacpan.org link

=head1 DESCRIPTION

This class inherit from L<Mojolicious::Plugin::LinkEmbedder::Link::HTML>.

=cut

use Mojo::Base 'Mojolicious::Plugin::LinkEmbedder::Link::Text::HTML';

=head1 ATTRIBUTES

=head2 provider_name

=cut

sub provider_name {'Metacpan'}

sub _learn_from_dom {
  my ($self, $dom) = @_;

  if (my $e = $dom->at('.author-pic > a > img') || $dom->at('link[rel="apple-touch-icon"]')) {
    my $url = $e->{src} || $e->{href};
    $self->image($url =~ /^https?:/ ? $url : "//metacpan.org$url");
  }

  $self->SUPER::_learn_from_dom($dom);
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;
