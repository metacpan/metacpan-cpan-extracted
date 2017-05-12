package Mojolicious::Plugin::LinkEmbedder::Link::Text::Ix;
use Mojo::Base 'Mojolicious::Plugin::LinkEmbedder::Link::Text';

has media_id => sub {
  shift->url->path =~ m!^/?(\w+)! ? $1 : '';
};

sub provider_name {'ix.io'}

sub learn {
  my ($self, $c, $cb) = @_;
  my $raw_url = $self->raw_url or return $self->SUPER::learn($c, $cb);

  $self->ua->get(
    $raw_url,
    sub {
      my ($ua, $tx) = @_;
      $self->{text} = Mojo::Util::xml_escape($tx->res->body) if $tx->success;
      $self->$cb;
    },
  );
}

sub pretty_url {
  my $self = shift;
  my $media_id = $self->media_id or return $self->SUPER::pretty_url;

  Mojo::URL->new("http://ix.io/$media_id/");
}

sub raw_url {
  my $self = shift;
  my $media_id = $self->media_id or return;

  Mojo::URL->new("http://ix.io/$media_id");
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::LinkEmbedder::Link::Text::Ix - ix.io link

=head1 DESCRIPTION

This class inherit from L<Mojolicious::Plugin::LinkEmbedder::Link::Text>.

=head1 OUTPUT HTML

This is an example output:

  <pre class="link-embedder text-paste">$txt</pre>

=head1 ATTRIBUTES

=head2 media_id

  $str = $self->media_id;

=head2 provider_name

=head1 METHODS

=head2 learn

=head2 pretty_url

Returns a pretty version of the L</url>. The default is to return a cloned
version of L</url>.

=head2 raw_url

=head1 AUTHOR

Jan Henning Thorsen

=cut
