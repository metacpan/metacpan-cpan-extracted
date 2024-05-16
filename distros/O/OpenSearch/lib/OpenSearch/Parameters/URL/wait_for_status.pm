
  package OpenSearch::Parameters::URL::wait_for_status;
  use Moose::Role;
  use Moose::Util::TypeConstraints;

  enum 'WaitForStatus' => [qw/green yellow red/];

  has "wait_for_status" => (
    is => "rw",
    isa => "WaitForStatus",
    documentation => {
      encode_func => undef,
      required => undef,
    }
  );

  around "wait_for_status" => sub {
    my $orig = shift;
    my $self = shift;

    if(@_) {
      $self->$orig(@_);
      return($self);
    }
    return($self->$orig);
  };

1;
