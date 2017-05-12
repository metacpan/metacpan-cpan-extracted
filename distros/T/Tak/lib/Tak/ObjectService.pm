package Tak::ObjectService;

use overload ();
use Moo;

with 'Tak::Role::Service';
with 'Tak::Role::ObjectMangling';

has proxied => (is => 'ro', init_arg => undef, default => sub { {} });

sub inflate {
  my ($self, $tag) = @_;
  $self->proxied->{$tag};
}

sub deflate {
  my ($self, $obj) = @_;
  my $tag = overload::StrVal($obj);
  $self->proxied->{$tag} = $obj;
  return +{ __proxied_object__ => $tag };
}

sub handle_call_method {
  my ($self, $context, $call) = @_;
  my ($invocant, $method, @args) = @{$self->decode_objects($call)};
  my @res;
  eval {
    if (!ref($invocant)) {
      (my $file = $invocant) =~ s/::/\//g;
      require "${file}.pm";
    }
    if ($context) {
      @res = $invocant->$method(@args);
    } elsif (defined $context) {
      $res[0] = $invocant->$method(@args);
    } else {
      $invocant->$method(@args);
    }
    1;
  } or die [ failure => "$@" ];
  return $self->encode_objects(\@res);
}

sub handle_remove_object {
  my ($self, $tag) = @_;
  my $had = !!delete $self->proxied->{$tag};
  return $had;
}

1;
