
  package OpenSearch::Parameters::URL::pre_filter_shard_size;
  use Moose::Role;

  has "pre_filter_shard_size" => (
    is => "rw",
    isa => "Int",
    documentation => {
      encode_func => undef,
      required => undef,
    }
  );

  around "pre_filter_shard_size" => sub {
    my $orig = shift;
    my $self = shift;

    if(@_) {
      $self->$orig(@_);
      return($self);
    }
    return($self->$orig);
  };

1;
