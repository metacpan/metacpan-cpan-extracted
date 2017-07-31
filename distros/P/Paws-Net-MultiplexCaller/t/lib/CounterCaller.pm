package CounterCaller {
  use Moose;
  with 'Paws::Net::CallerRole';
  use Test::More;
  has called_me_times => (
    is => 'ro',
    default => 0,
    traits => [ 'Counter' ],
    handles => {
      register_call => 'inc',
    }
  );
  sub do_call {
    my $self = shift;
    $self->register_call;
  }
  sub caller_to_response { }
}

1;
