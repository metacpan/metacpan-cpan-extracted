package Mojolicious::Plugin::LinkEmbedder::Link::Text::Github;
use Mojo::Base 'Mojolicious::Plugin::LinkEmbedder::Link::Text::HTML';

sub provider_name {'Github'}

sub _learn_from_dom {
  my ($self, $dom) = @_;
  my $e;

  $self->SUPER::_learn_from_dom($dom);
  $self->title($e->text) if $e = $dom->at('title');

  for my $e ($dom->find('#readme p')->each) {
    my $text = $e->text || '';
    $text =~ /\w/ or next;
    $self->title($self->description);
    $self->description($text);
    last;
  }

  if ($self->url->path =~ m!/commit!) {
    $self->image($e->{src}) if $e = $dom->at('img.avatar') and $e->{src};
    $self->title($e->all_text)       if $e = $dom->at('.commit-title');
    $self->description($e->all_text) if $e = $dom->at('.commit-author-section');
  }
  elsif ($self->url->path =~ m!/(?:issue|pull)!) {
    $self->image($e->{src}) if $e = $dom->at('img.timeline-comment-avatar') and $e->{src};
    $self->title($e->text) if $e = $dom->at('.js-issue-title');
    $self->description($e->all_text) if $e = eval { $dom->at('#partial-discussion-header a.author')->parent };
  }
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::LinkEmbedder::Link::Text::Github - github.com link

=head1 DESCRIPTION

This class inherit from L<Mojolicious::Plugin::LinkEmbedder::Link::Text::HTML>.

=head1 ATTRIBUTES

=head2 provider_name

=head1 AUTHOR

Jan Henning Thorsen

=cut
