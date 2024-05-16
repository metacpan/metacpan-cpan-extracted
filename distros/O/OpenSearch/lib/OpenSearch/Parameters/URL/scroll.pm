
  package OpenSearch::Parameters::URL::scroll;
  use Moose::Role;

  has "scroll" => (
    is => "rw",
    isa => "Str",
    documentation => {
      encode_func => undef,
      required => undef,
    }
  );

  around "scroll" => sub {
    my $orig = shift;
    my $self = shift;

    if(@_) {
      $self->$orig(@_);
      return($self);
    }
    return($self->$orig);
  };

1;
