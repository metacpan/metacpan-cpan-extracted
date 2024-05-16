
  package OpenSearch::Parameters::Body::index;
  use Moose::Role;

  has "index" => (
    is => "rw",
    isa => "Str",
    documentation => {
      encode_func => undef,
      required => undef,
    }
  );

  around "index" => sub {
    my $orig = shift;
    my $self = shift;
    
    if(@_) {
      $self->$orig(@_);
      return($self);
    }
    return($self->$orig);
  };

1;
