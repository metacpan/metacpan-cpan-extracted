
  package OpenSearch::Parameters::URL::sort;
  use Moose::Role;

  has "sort" => (
    is            => "rw",
    isa           => "ArrayRef[HashRef]",
    documentation => {
      encode_func => undef,
      required    => undef,
    }
  );

  around "sort" => sub {
    my $orig = shift;
    my $self = shift;

    if (@_) {
      $self->$orig(@_);
      return ($self);
    }
    return ( $self->$orig );
  };

  1;
