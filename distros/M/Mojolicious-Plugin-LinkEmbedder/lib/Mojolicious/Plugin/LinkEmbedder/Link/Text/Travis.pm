package Mojolicious::Plugin::LinkEmbedder::Link::Text::Travis;
use Mojo::Base 'Mojolicious::Plugin::LinkEmbedder::Link';

has media_id => sub {
  shift->url->path =~ m!^/(.*/builds/\d+)$! ? $1 : '';
};

sub provider_name {'Travis'}

sub learn {
  my ($self, $c, $cb) = @_;
  my $ua  = $self->ua;
  my $url = Mojo::URL->new('https://api.travis-ci.org/repositories');

  push @{$url->path}, split '/', $self->media_id;

  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $ua->get($url, $delay->begin);
    },
    sub {
      my ($ua, $tx) = @_;
      $self->{json} = $tx->res->json;
      $self->$cb;
    },
  );
}

sub to_embed {
  my $self        = shift;
  my $json        = $self->{json};
  my $description = $json->{message} || '';
  my $title;

  if ($json->{finished_at}) {
    $title = sprintf 'Build %s at %s', $json->{status} ? 'failed' : 'succeeded', $json->{finished_at};
  }
  elsif ($json->{started_at}) {
    $title = sprintf 'Started building at %s.', $json->{started_at};
  }
  else {
    $title = 'Build has not been started.';
  }

  if ($description) {
    $description = "$json->{author_name}: $description" if $json->{author_name};
    return $self->tag(
      div => class => 'link-embedder text-html',
      sub {
        join(
          '',
          $self->tag(
            div => class => 'link-embedder-media',
            sub {
              $self->tag(img => src => 'https://travis-ci.com/img/travis-mascot-200px.png', alt => 'Travis logo');
            }
          ),
          $self->tag(h3 => $title),
          $self->tag(p  => $description),
          $self->tag(
            div => class => 'link-embedder-link',
            sub {
              $self->tag(a => href => $self->url, title => $self->url, $self->url);
            }
          )
        );
      }
    );
  }

  return $self->SUPER::to_embed(@_);
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::LinkEmbedder::Link::Text::Travis - https://travis-ci.org link

=head1 ATTRIBUTES

=head2 media_id

  $str = $self->media_id;

Example C<$str>: "Nordaaker/convos/builds/47421379".

=head2 provider_name

=head1 METHODS

=head2 learn

=head2 to_embed

Returns data about the HTML page in a div tag.

=head1 AUTHOR

Jan Henning Thorsen

=cut
