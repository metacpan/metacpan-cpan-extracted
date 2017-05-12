package Tak::Role::ObjectMangling;

use Scalar::Util qw(weaken);
use JSON::PP qw(encode_json decode_json);

use Moo::Role;

requires 'inflate';
requires 'deflate';

has encoder_json => (is => 'lazy');
has decoder_json => (is => 'lazy');

sub _build_encoder_json {
  JSON::PP->new->allow_nonref(1)->convert_blessed(1);
}

sub _build_decoder_json {
  my $self = shift;
  weaken($self);
  JSON::PP->new->allow_nonref(1)->filter_json_single_key_object(
    __proxied_object__ => sub { $self->inflate($_[0]) }
  );
}

sub encode_objects {
  my ($self, $data) = @_;
  no warnings 'once';
  local *UNIVERSAL::TO_JSON = sub { $self->deflate($_[0]) };
  decode_json($self->encoder_json->encode($data));
}

sub decode_objects {
  my ($self, $data) = @_;
  $self->decoder_json->decode(encode_json($data));
}

1;
