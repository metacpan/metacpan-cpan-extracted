
  package OpenSearch::Parameters::URL::max_concurrent_shard_requests;
  use Moose::Role;

  has "max_concurrent_shard_requests" => (
    is => "rw",
    isa => "Int",
    documentation => {
      encode_func => undef,
      required => undef,
    }
  );

  around "max_concurrent_shard_requests" => sub {
    my $orig = shift;
    my $self = shift;

    if(@_) {
      $self->$orig(@_);
      return($self);
    }
    return($self->$orig);
  };

1;
