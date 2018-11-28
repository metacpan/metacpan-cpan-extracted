package Mojolicious::Plugin::MountPSGI::Proxy;
use Mojo::Base 'Mojolicious';
use Plack::Util;

has app => sub {
  my $self = shift;
  local $ENV{PLACK_ENV} = $self->mode;
  Plack::Util::load_psgi $self->script;
};
has mode => sub { $ENV{PLACK_ENV} || 'development' };
has 'script';
has 'rewrite';

sub handler {
  my ($self, $c) = @_;
  local $ENV{PLACK_ENV} = $self->mode;

  my $plack_env = _mojo_req_to_psgi_env($c, $self->rewrite);
  $plack_env->{'MOJO.CONTROLLER'} = $c;
  my $plack_res = Plack::Util::run_app $self->app, $plack_env;

  # simple (array reference) response
  if (ref $plack_res eq 'ARRAY') {
    my ($mojo_res, undef) = _psgi_res_to_mojo_res($plack_res);
    $c->tx->res($mojo_res);
    $c->rendered;
    return;
  }

  # PSGI responses must be ARRAY or CODE
  die 'PSGI response not understood'
    unless ref $plack_res eq 'CODE';

  #TODO do something with $self->mode in delayed response
  # delayed (code reference) response
  my $responder = sub {
    my $plack_res = shift;
    my ($mojo_res, $streaming) = _psgi_res_to_mojo_res($plack_res);
    $c->tx->res($mojo_res);

    return $c->rendered unless $streaming;

    # streaming response, possibly chunked
    my $chunked = $mojo_res->content->is_chunked;
    my $write = $chunked ? sub { $c->write_chunk(@_) } : sub { $c->write(@_) };
    $write->(); # finalize header response
    return Plack::Util::inline_object(
      write => $write,
      close => sub { $c->finish(@_) }
    );
  };
  $plack_res->($responder);
}

sub _mojo_req_to_psgi_env {
  my $c = shift;
  my $rewrite = shift;
  my $mojo_tx = $c->tx;
  my $mojo_req = $c->req;
  my $url = $mojo_req->url;
  my $base = $url->base;
  my $content = $mojo_req->content;
  my $body;
  if ($content->is_multipart) {
    $content = $content->clone;
    my $offset = 0;
    while (1) {
      my $chunk = $content->get_body_chunk($offset);
      next unless defined $chunk;
      my $len = length $chunk;
      last unless $len;
      $offset += $len;
      $body   .= $chunk;
    }
  } else {
    $body = $mojo_req->body;
  }
  open my $input, '<', \$body or die "Cannot open handle to scalar reference: $!";

  my %headers = %{$mojo_req->headers->to_hash};
  for my $key (keys %headers) {
    my $value = $headers{$key};
    delete $headers{$key};
    $key =~ s{-}{_}g;
    $headers{'HTTP_'. uc $key} = $value;
  }

  # certain headers get their own psgi slot
  for my $key (qw/CONTENT_LENGTH CONTENT_TYPE/) {
    next unless exists $headers{"HTTP_$key"};
    $headers{$key} = delete $headers{"HTTP_$key"};
  }

  my $path = $url->path->to_string;
  my $script = '';
  if ($rewrite) {
    $script = $rewrite if $path =~ s/\Q$rewrite//;
    $path = "/$path" unless $path =~ m[^/];
  }

  return {
    %ENV,
    %headers,
    'REMOTE_ADDR'       => $mojo_tx->remote_address,
    'REMOTE_HOST'       => $mojo_tx->remote_address,
    'REMOTE_PORT'       => $mojo_tx->remote_port,
    'SERVER_PROTOCOL'   => 'HTTP/'. $mojo_req->version,
    'SERVER_NAME'       => $base->host,
    'SERVER_PORT'       => $base->port,
    'REQUEST_METHOD'    => $mojo_req->method,
    'SCRIPT_NAME'       => $script,
    'PATH_INFO'         => $path,
    'REQUEST_URI'       => $url->to_string,
    'QUERY_STRING'      => $url->query->to_string,
    'psgi.url_scheme'   => $base->scheme,
    'psgi.multithread'  => Plack::Util::FALSE,
    'psgi.version'      => [1,1],
    'psgi.errors'       => *STDERR,
    'psgi.input'        => $input,
    'psgi.multithread'  => Plack::Util::FALSE,
    'psgi.multiprocess' => Plack::Util::TRUE,
    'psgi.run_once'     => Plack::Util::FALSE,
    'psgi.streaming'    => Plack::Util::TRUE,
    'psgi.nonblocking'  => Plack::Util::FALSE,
  };
}

sub _psgi_res_to_mojo_res {
  my $psgi_res = shift;
  my $mojo_res = Mojo::Message::Response->new;
  $mojo_res->code($psgi_res->[0]);

  my $headers = $mojo_res->headers;
  Plack::Util::header_iter $psgi_res->[1] => sub { $headers->header(@_) };
  $headers->remove('Content-Length'); # should be set by mojolicious later

  my $streaming = 0;
  if (@$psgi_res == 3) {
    my $asset = $mojo_res->content->asset;
    Plack::Util::foreach($psgi_res->[2], sub {$asset->add_chunk($_[0])});
  } else {
    $streaming = 1;
  }

  return ($mojo_res, $streaming);
}

1;

