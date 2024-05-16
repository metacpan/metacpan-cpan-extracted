
  package OpenSearch::Parameters::URL::from;
  use Moose::Role;

  has "from" => (
    is => "rw",
    isa => "Int",
    documentation => {
      encode_func => undef,
      required => undef,
    }
  );

  around "from" => sub {
    my $orig = shift;
    my $self = shift;

    if(@_) {
      $self->$orig(@_);
      return($self);
    }
    return($self->$orig);
  };

1;
