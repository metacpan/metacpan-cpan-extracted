
  package OpenSearch::Parameters::Body::shard;
  use Moose::Role;

  has "shard" => (
    is => "rw",
    isa => "Int",
    documentation => {
      encode_func => undef,
      required => undef,
    }
  );

  around "shard" => sub {
    my $orig = shift;
    my $self = shift;

    if(@_) {
      $self->$orig(@_);
      return($self);
    }
    return($self->$orig);
  };

1;
