
  package OpenSearch::Parameters::URL::ccs_minimize_roundtrips;
  use Moose::Role;

  has "ccs_minimize_roundtrips" => (
    is => "rw",
    isa => "Bool",
    documentation => {
      encode_func => "encode_bool",
      required => undef,
    }
  );

  around "ccs_minimize_roundtrips" => sub {
    my $orig = shift;
    my $self = shift;

    if(@_) {
      $self->$orig(@_);
      return($self);
    }
    return($self->$orig);
  };

1;
