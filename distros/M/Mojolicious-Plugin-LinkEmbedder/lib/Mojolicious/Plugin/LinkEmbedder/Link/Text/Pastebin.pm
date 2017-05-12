package Mojolicious::Plugin::LinkEmbedder::Link::Text::Pastebin;
use Mojo::Base 'Mojolicious::Plugin::LinkEmbedder::Link::Text';

has media_id => sub {
  shift->url->path =~ m!^/?(\w+)! ? $1 : '';
};

sub provider_name {'pastebin.com'}

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

sub raw_url {
  my $self = shift;
  my $media_id = $self->media_id or return;

  Mojo::URL->new('http://pastebin.com/raw.php')->query(i => $media_id);
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::LinkEmbedder::Link::Text::Pastebin - pastebin.com link

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

=head2 raw_url

=head1 AUTHOR

Jan Henning Thorsen

=cut
