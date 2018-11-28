use Plack::Request;
use Mojo::File 'path';

my $app = sub {
  my $env = shift;
  my $req = Plack::Request->new($env);

  my $res = $req->parameters->as_hashref;
  my $uploads = $req->uploads;
  for my $name (keys %$uploads) {
    my $upload = $uploads->{$name};
    $res->{_upload}{$name} = [$upload->size, $upload->filename, path($upload->path)->slurp];
  }
  return [200, ['Content-Type' => 'application/json'], [Mojo::JSON::encode_json($res)]];
};
