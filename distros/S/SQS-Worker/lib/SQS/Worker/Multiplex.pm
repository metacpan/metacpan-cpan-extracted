package SQS::Worker::Multiplex {
  use Moose::Role;

  has dispatch => (
    is => 'ro',
    isa => 'HashRef[CodeRef]',
    required => 1
  );

  sub process_message {
    my ($self, $f, @args) = @_;

    my $function = $self->dispatch->{ $f };

    die "The function '$f' is not defined in the dispatch table" if (not defined $function);

    $function->($self, @args);
  }
}
1;
