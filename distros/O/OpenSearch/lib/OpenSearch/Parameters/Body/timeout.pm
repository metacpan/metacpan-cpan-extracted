
  package OpenSearch::Parameters::Body::timeout;
  use Moose::Role;

  has "timeout" => (
    is => "rw",
    isa => "Time",
    documentation => {
      encode_func => undef,
      required => undef,
    }
  );

  around "timeout" => sub {
    my $orig = shift;
    my $self = shift;

    if(@_) {
      $self->$orig(@_);
      return($self);
    }
    return($self->$orig);
  };

1;
