package Mojolicious::Command::nopaste::Service::gist;
use Mojo::Base 'Mojolicious::Command::nopaste::Service';
use Mojo::Path;
use File::HomeDir;
use File::Spec ();
use Mojo::URL;

has description => "Post to gist.github.com\n";
has token => sub {
  my $self = shift;
  return $ENV{GIST_TOKEN} if $ENV{GIST_TOKEN};
  my $home = File::HomeDir->my_home;
  my $path = File::Spec->catfile($home, '.gist_token');
  return undef unless -e $path;
  my $token = $self->slurp($path);
  chomp $token;
  return $token || undef;
};

my $token_usage = <<'TOKEN';
A token is required for posting to gist.

See how to create one at:
  https://help.github.com/articles/creating-an-access-token-for-command-line-use
To specify your token one the command line, set the --token (-t) command line
switch to a path to your token or the token value itself.
Alternatively you can specify the token using the GIST_TOKEN env variable, or
by creating a file called .gist_token in your home directory.

TOKEN

has service_usage => $token_usage;

sub paste {
  my $self = shift;
  my $token = $self->token or die $token_usage;
  my $data = {
    public => $self->private ? \0 : \1,
  };

  my $files = $self->files;
  if (@$files) {
    $data->{files}{Mojo::Path->new($_)->[-1]}{content} = $self->slurp($_) for @$files;
  } else {
    $data->{files}{noname}{content} = $self->slurp;
  }

  $data->{description} = $self->desc if $self->desc;

  my $url    = Mojo::URL->new('https://api.github.com/gists');
  my $method = 'POST';

  if (my $update = $self->update) {
    push @{ $url->path->parts }, $update;
    $method = 'PATCH';
  }

  my $ua = $self->ua;
  my $tx = $ua->build_tx(
    $method => $url,
    {
      Accept => 'application/vnd.github.v3+json',
      Authorization => "token $token",
      'User-Agent' => 'Mojolicious-Command-nopaste (author: jberger)',
    },
    json => $data,
  );
  $ua->start($tx);

  if (my $error = $tx->error) {
    if ($error->{code}) {
      say "Request failed, code $error->{code}: $error->{message}";
      say $tx->res->body;
    } else {
      say "Connection error: $error->{message}";
    }
    exit 1;
  }

  return $tx->res->json->{html_url};
}

1;

