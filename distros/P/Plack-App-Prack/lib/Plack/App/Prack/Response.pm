package Plack::App::Prack::Response;

use strict;
use warnings;

use JSON;

sub new {
  my ($class, $sock) = @_;

  die "socket is required" unless $sock;

  my $self = bless { sock => $sock }, $class;

  $self->read;

  return $self;
}

sub read {
  my $self = shift;

  my $chunk = $self->read_ns;

  # doesn't look like a status code, probably a stack trace
  if ($chunk !~ /^\d+/) {
    return $self->handle_error($chunk);
  }

  $self->{status} = $chunk;
  $self->{headers} = decode_json $self->read_ns;
  $self->{body} = [];

  while (my $chunk = $self->read_ns) {
    push @{$self->{body}}, $chunk;
  }
  
  $self->{sock}->shutdown(0);
}

sub handle_error {
  my ($self, $json) = @_;
  my $stack = decode_json $json;
  die join "\n", map {$stack->{$_}} qw/name message stack/;
}

sub headers {
  my $self = shift;
  if ($self->{headers}) {
    return [ %{$self->{headers}} ];
  }

  return [];
}

sub status {
  my $self = shift;
  return $self->{status} || 500;
}

sub body {
  my $self = shift;
  if ($self->{body}) {
    return $self->{body};
  }
  return [];
}

sub to_psgi {
  my $self = shift;
  return [$self->status, $self->headers, $self->body]
}

sub read_ns {
  my $self = shift;
  my $buf;

  do {
    $buf .= $self->{sock}->getc;
  } while ($buf !~ s/^(0|[1-9][0-9]*)://);
  
  my $len = $1;

  $self->{sock}->read($buf, $len);
  $self->{sock}->read(my $term, 1);

  return $buf;
}

1;
