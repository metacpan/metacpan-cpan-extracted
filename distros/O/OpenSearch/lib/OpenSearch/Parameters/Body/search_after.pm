
  package OpenSearch::Parameters::Body::search_after;
  use Moose::Role;

  has "search_after" => (
    is            => "rw",
    isa           => "ArrayRef",
    documentation => {
      encode_func => undef,
      required    => undef,
    }
  );

  around "search_after" => sub {
    my $orig = shift;
    my $self = shift;

    if (@_) {
      $self->$orig(@_);
      return ($self);
    }
    return ( $self->$orig );
  };

  1;
