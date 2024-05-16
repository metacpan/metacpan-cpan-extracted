
  package OpenSearch::Parameters::Body::fields;
  use Moose::Role;

  has "fields" => (
    is            => "rw",
    isa           => "ArrayRef",
    documentation => {
      encode_func => undef,
      required    => undef,
    }
  );

  around "fields" => sub {
    my $orig = shift;
    my $self = shift;

    if (@_) {
      $self->$orig(@_);
      return ($self);
    }
    return ( $self->$orig );
  };

  1;
