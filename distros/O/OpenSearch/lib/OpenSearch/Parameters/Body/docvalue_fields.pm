
  package OpenSearch::Parameters::Body::docvalue_fields;
  use Moose::Role;

  has "docvalue_fields" => (
    is => "rw",
    isa => "ArrayRef[HashRef]",
    documentation => {
      encode_func => undef,
      required => undef,
    }
  );

  around "docvalue_fields" => sub {
    my $orig = shift;
    my $self = shift;

    if(@_) {
      $self->$orig(@_);
      return($self);
    }
    return($self->$orig);
  };

1;
