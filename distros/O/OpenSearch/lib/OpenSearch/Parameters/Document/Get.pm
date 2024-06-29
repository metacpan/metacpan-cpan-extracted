package OpenSearch::Parameters::Document::Get;
use strict;
use warnings;
use feature               qw(state);
use Types::Standard       qw(Str Bool Int Enum);
use Types::Common::String qw(NonEmptyStr);
use Moo::Role;

with 'OpenSearch::Parameters';

has 'index' => (
  is       => 'rw',
  isa      => NonEmptyStr,
  required => 1,
);

has 'id' => (
  is       => 'rw',
  isa      => NonEmptyStr,
  required => 1,
);

has 'preference' => (
  is  => 'rw',
  isa => Str,
);

has 'realtime' => (
  is  => 'rw',
  isa => Bool,
);

has 'refresh' => (
  is  => 'rw',
  isa => Bool,
);

has 'routing' => (
  is  => 'rw',
  isa => Str,
);

has 'stored_fields' => (
  is  => 'rw',
  isa => Bool,
);

has '_source' => (
  is  => 'rw',
  isa => Str,
);

has '_source_includes' => (
  is  => 'rw',
  isa => Str,
);

has '_source_excludes' => (
  is  => 'rw',
  isa => Str,
);

has 'version' => (
  is  => 'rw',
  isa => Int,
);

has 'version_type' => (
  is  => 'rw',
  isa => Enum [qw(internal external external_gte)],
);

around [
  qw/
    index id preference realtime refresh routing stored_fields _source _source_includes _source_excludes version version_type
    /
] => sub {
  my $orig = shift;
  my $self = shift;

  if (@_) {
    $self->$orig(@_);
    return ($self);
  }
  return ( $self->$orig );
};

sub api_spec {
  state $s = +{
    index => {
      encode_func => 'as_is',
      type        => 'path',
    },
    id => {
      encode_func => 'as_is',
      type        => 'path',
    },
    preference => {
      encode_func => 'as_is',
      type        => 'url',
    },
    realtime => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    refresh => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    routing => {
      encode_func => 'as_is',
      type        => 'body',
    },
    stored_fields => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    _source => {
      encode_func => 'as_is',
      type        => 'url',
    },
    _source_includes => {
      encode_func => 'as_is',
      type        => 'url',
    },
    _source_excludes => {
      encode_func => 'as_is',
      type        => 'url',
    },
    version => {
      encode_func => 'as_is',
      type        => 'url',
    },
    version_type => {
      encode_func => 'as_is',
      type        => 'url',
    }
  };
}

1;
