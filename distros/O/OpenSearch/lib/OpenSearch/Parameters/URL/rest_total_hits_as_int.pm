
  package OpenSearch::Parameters::URL::rest_total_hits_as_int;
  use Moose::Role;

  has "rest_total_hits_as_int" => (
    is => "rw",
    isa => "Bool",
    documentation => {
      encode_func => "encode_bool",
      required => undef,
    }
  );

  around "rest_total_hits_as_int" => sub {
    my $orig = shift;
    my $self = shift;

    if(@_) {
      $self->$orig(@_);
      return($self);
    }
    return($self->$orig);
  };

1;
