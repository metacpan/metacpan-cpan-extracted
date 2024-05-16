
  package OpenSearch::Parameters::Body::explain;
  use Moose::Role;

  has "explain" => (
    is => "rw",
    isa => "Str",
    documentation => {
      encode_func => undef,
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
