
  package OpenSearch::Parameters::URL::version;
  use Moose::Role;

  has "version" => (
    is => "rw",
    isa => "Bool",
    documentation => {
      encode_func => "encode_bool",
      required => undef,
    }
  );

  around "version" => sub {
    my $orig = shift;
    my $self = shift;

    if(@_) {
      $self->$orig(@_);
      return($self);
    }
    return($self->$orig);
  };

1;
