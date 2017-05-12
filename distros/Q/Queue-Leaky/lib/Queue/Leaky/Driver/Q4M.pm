package Queue::Leaky::Driver::Q4M;

use Moose;
use Queue::Q4M;

has 'connect_info' => (
    is => 'rw',
    isa => 'ArrayRef',
    required => 1
);

has 'q4m' => (
    is      => 'rw',
    isa     => 'Queue::Q4M',
    handles => {
        next   => 'next',
        insert => 'insert',
        clear  => 'clear',
        fetch  => 'fetch_hashref',
    },
);

with 'Queue::Leaky::Driver';

__PACKAGE__->meta->make_immutable;

no Moose;

sub BUILD {
    my $self = shift;
    $self->q4m(
        Queue::Q4M->connect( connect_info => $self->connect_info )
    );
    $self;
}

1;

__END__

=head1 NAME 

Queue::Leaky::Driver::Q4M - Queue::Q4M Implementation

=head1 SYNOPSIS

  use Queue::Leaky::Driver::Q4M;

  my $queue = Queue::Leaky::Driver::Q4M->new(
  );

  $queue->next( ... );

  $queue->fetch( ... );

  $queue->insert( ... );

  $queue->clear( ... );

=head1 METHODS

=head2 next

=head2 fetch

=head2 insert

=head2 clear

=cut
