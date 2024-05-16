
  package OpenSearch::Parameters::URL::_source_excludes;
  use Moose::Role;

  has "_source_excludes" => (
    is => "rw",
    isa => "List",
    documentation => {
      encode_func => undef,
      required => undef,
    }
  );

  around "_source_excludes" => sub {
    my $orig = shift;
    my $self = shift;

    if(@_) {
      $self->$orig(@_);
      return($self);
    }
    return($self->$orig);
  };

1;
