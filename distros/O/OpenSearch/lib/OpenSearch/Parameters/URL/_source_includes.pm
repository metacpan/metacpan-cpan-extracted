
  package OpenSearch::Parameters::URL::_source_includes;
  use Moose::Role;

  has "_source_includes" => (
    is => "rw",
    isa => "List",
    documentation => {
      encode_func => undef,
      required => undef,
    }
  );

  around "_source_includes" => sub {
    my $orig = shift;
    my $self = shift;

    if(@_) {
      $self->$orig(@_);
      return($self);
    }
    return($self->$orig);
  };

1;
