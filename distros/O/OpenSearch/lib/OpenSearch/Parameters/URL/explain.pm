
  package OpenSearch::Parameters::URL::explain;
  use Moose::Role;

  has "explain" => (
    is => "rw",
    isa => "Bool",
    documentation => {
      encode_func => "encode_bool",
      required => undef,
    }
  );

  around "explain" => sub {
    my $orig = shift;
    my $self = shift;

    if(@_) {
      $self->$orig(@_);
      return($self);
    }
    return($self->$orig);
  };

1;
