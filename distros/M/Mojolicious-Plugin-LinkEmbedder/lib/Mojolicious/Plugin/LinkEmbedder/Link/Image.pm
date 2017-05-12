package Mojolicious::Plugin::LinkEmbedder::Link::Image;
use Mojo::Base 'Mojolicious::Plugin::LinkEmbedder::Link';

sub to_embed {
  my $self = shift;
  my %args = @_;

  $self->tag(img => src => $self->url, alt => $args{alt} || $self->url);
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::LinkEmbedder::Link::Image - Base class for image links

=head1 DESCRIPTION

This class inherit from L<Mojolicious::Plugin::LinkEmbedder::Link>.

=head1 METHODS

=head2 to_embed

Returns an img tag.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut
