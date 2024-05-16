
  package OpenSearch::Parameters::URL::cancel_after_time_interval;
  use Moose::Role;

  has "cancel_after_time_interval" => (
    is => "rw",
    isa => "Time",
    documentation => {
      encode_func => undef,
      required => undef,
    }
  );

  around "cancel_after_time_interval" => sub {
    my $orig = shift;
    my $self = shift;

    if(@_) {
      $self->$orig(@_);
      return($self);
    }
    return($self->$orig);
  };

1;
