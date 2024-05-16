
  package OpenSearch::Parameters::Body::current_node;
  use Moose::Role;

  has "current_node" => (
    is => "rw",
    isa => "Str",
    documentation => {
      encode_func => undef,
      required => undef,
    }
  );

  around "current_node" => sub {
    my $orig = shift;
    my $self = shift;

    if(@_) {
      $self->$orig(@_);
      return($self);
    }
    return($self->$orig);
  };

1;
