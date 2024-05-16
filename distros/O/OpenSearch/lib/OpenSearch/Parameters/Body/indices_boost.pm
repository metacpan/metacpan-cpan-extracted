
  package OpenSearch::Parameters::Body::indices_boost;
  use Moose::Role;

  has "indices_boost" => (
    is => "rw",
    isa => "ArrayRef[HashRef]",
    documentation => {
      encode_func => undef,
      required => undef,
    }
  );

  around "indices_boost" => sub {
    my $orig = shift;
    my $self = shift;

    if(@_) {
      $self->$orig(@_);
      return($self);
    }
    return($self->$orig);
  };

1;
