
  package OpenSearch::Parameters::URL::wait_for_no_relocating_shards;
  use Moose::Role;

  has "wait_for_no_relocating_shards" => (
    is => "rw",
    isa => "Bool",
    documentation => {
      encode_func => "encode_bool",
      required => undef,
    }
  );

  around "wait_for_no_relocating_shards" => sub {
    my $orig = shift;
    my $self = shift;

    if(@_) {
      $self->$orig(@_);
      return($self);
    }
    return($self->$orig);
  };

1;
