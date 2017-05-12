package Mojo::ACME::CA;

use Mojo::Base -base;

use Mojo::URL;
use Scalar::Util ();

has agreement => 'https://letsencrypt.org/documents/LE-SA-v1.0.1-July-27-2015.pdf';
has intermediate => sub { die 'intermediate cert not defined' };
has name => 'Unknown CA';
has test_mode => 0;

has [qw/primary_url test_url/] => '';

sub url {
  my ($self, $path) = @_;
  die 'URL not defined'
    unless my $url = $self->test_mode ? $self->test_url : $self->primary_url;

  $url =
    Scalar::Util::blessed($url) && $url->isa('Mojo::URL')
    ? $url->clone
    : Mojo::URL->new("$url");

  $url->path($path) if $path;
  return $url;
}

1;

