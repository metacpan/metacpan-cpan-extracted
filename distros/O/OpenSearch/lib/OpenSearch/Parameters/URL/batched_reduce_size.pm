
  package OpenSearch::Parameters::URL::batched_reduce_size;
  use Moose::Role;

  has "batched_reduce_size" => (
    is => "rw",
    isa => "Int",
    documentation => {
      encode_func => undef,
      required => undef,
    }
  );

  around "batched_reduce_size" => sub {
    my $orig = shift;
    my $self = shift;

    if(@_) {
      $self->$orig(@_);
      return($self);
    }
    return($self->$orig);
  };

1;
