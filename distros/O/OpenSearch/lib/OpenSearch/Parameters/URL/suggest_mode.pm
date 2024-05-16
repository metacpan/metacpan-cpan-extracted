
  package OpenSearch::Parameters::URL::suggest_mode;
  use Moose::Role;

  has "suggest_mode" => (
    is => "rw",
    isa => "Str",
    documentation => {
      encode_func => undef,
      required => undef,
    }
  );

  around "suggest_mode" => sub {
    my $orig = shift;
    my $self = shift;

    if(@_) {
      $self->$orig(@_);
      return($self);
    }
    return($self->$orig);
  };

1;
