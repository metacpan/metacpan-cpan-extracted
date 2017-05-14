package Mojolicious::Plugin::LinkEmbedder::Link::Text::PasteScsysCoUk;

=head1 NAME

Mojolicious::Plugin::LinkEmbedder::Link::Text::PasteScsysCoUk - paste.scsys.co.uk link

=head1 DESCRIPTION

This class inherit from L<Mojolicious::Plugin::LinkEmbedder::Link::Text>.

=head1 OUTPUT HTML

This is an example output:

  <pre class="link-embedder text-paste">$txt</pre>

=cut

use Mojo::Base 'Mojolicious::Plugin::LinkEmbedder::Link::Text';
use Mojo::Util ();

=head1 ATTRIBUTES

=head2 media_id

  $str = $self->media_id;

=cut

has media_id => sub {
  shift->url->path =~ m!^/?(\d+)! ? $1 : '';
};

=head2 provider_name

=cut

sub provider_name {'scsys.co.uk'}

=head1 METHODS

=head2 learn

=cut

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

=head2 raw_url

=cut

sub raw_url {
  my $self = shift;
  my $media_id = $self->media_id or return;

  Mojo::URL->new("http://paste.scsys.co.uk/$media_id?tx=on");
}

=head1 AUTHOR

Jan Henning Thorsen

=cut

1;
