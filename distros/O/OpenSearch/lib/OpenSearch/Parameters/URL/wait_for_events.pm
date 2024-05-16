
  package OpenSearch::Parameters::URL::wait_for_events;
  use Moose::Role;
  use Moose::Util::TypeConstraints;

  enum 'WaitForEvents' => [qw/immediate urgent high normal low languid/];

  has "wait_for_events" => (
    is => "rw",
    isa => "WaitForEvents",
    documentation => {
      encode_func => undef,
      required => undef,
    }
  );

  around "wait_for_events" => sub {
    my $orig = shift;
    my $self = shift;

    if(@_) {
      $self->$orig(@_);
      return($self);
    }
    return($self->$orig);
  };

1;
