package Plack::App::Prack::Request;

use strict;
use warnings;

use JSON;
use Plack::App::Prack::Response;

my @ENV_KEYS = qw/REQUEST_METHOD PATH_INFO QUERY_STRING 
                  SERVER_NAME SERVER_PORT/;

sub new {
  my ($class, $file, $env) = @_;

  die "env is required" unless $env;
  die "file is required" unless $file;

  my $self = bless {
    env => $env,
    file => $file,
  }, $class;

  $self->connect;
  $self->write;

  return $self;
}

sub connect {
  my $self = shift;

  $self->{sock} = IO::Socket::UNIX->new(Peer => $self->{file});

  if (!$self->{sock}) {
    die "could not connect to nack server at $self->{file}\n";
  }
}

sub response {
  my $self = shift;

  return Plack::App::Prack::Response->new($self->{sock});
}

sub encode_ns {
  my $data = shift;
  return length($data).":".$data.",";
}

sub write {
  my $self = shift;

  my $env = encode_json($self->_filter_env($self->{env}));

  my $input = "";
  my $buf = "";

  while ($self->{env}->{'psgi.input'}->read($buf, 1024)) {
    $input .= $buf;
  }

  $self->_write($env, $input);
  $self->{sock}->shutdown(1);
}

sub _write {
  my ($self, @strings) = @_;
  $self->{sock}->write(join "", map {encode_ns $_} @strings);
}

sub _filter_env {
  my ($self, $env) = @_;

  +{
    SERVER_ADDR => '0.0.0.0',
    REMOTE_ADDR => '0.0.0.0',
    SCRIPT_NAME => "",
    map {$_ => $env->{$_}} @ENV_KEYS, grep {/^HTTP_/} keys %$env
  }
}

1;
