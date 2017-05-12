package MooseX::Workers::Job;
our $AUTHORITY = 'cpan:PERIGRIN';
$MooseX::Workers::Job::VERSION = '0.24';
use Moose;
use overload ();
use Scalar::Util 'reftype';

use overload
    '""' => sub { $_[0]->ID }, # stringify to wheel id for backcompat
    fallback => 1
;

has 'ID'      => ( is => 'rw', isa => 'Int' );   # POE::Wheel::Run->ID
has 'PID'     => ( is => 'rw', isa => 'Int' );   # POE::Wheel::Run->PID
has 'name'    => ( is => 'rw', isa => 'Str' );
has 'command' => ( is => 'rw' );  # See POE::Wheel::Run POD (Program)
has 'args'    => ( is => 'rw', isa => 'ArrayRef' );              # See POE::Wheel::Run POD (ProgramArgs)
has 'timeout' => ( is => 'rw', isa => 'Int' );   # abort after this many seconds

sub is_coderef {
    my $self = shift;

    my $cmd = $self->command;

    return 1 if ref $cmd && (reftype $cmd eq 'CODE' || overload::Method($cmd, '&{}'));

    return undef;
}

__PACKAGE__->meta->make_immutable;

no Moose;

=head1 NAME

MooseX::Workers::Job - One of the jobs MooseX::Workers is running

=head1 SYNOPSIS

  package Manager;
  use Moose;
  with qw(MooseX::Workers);

  sub worker_stdout {
      my ( $self, $output, $job ) = @_;
      printf(
          "%s(%s,%s) said '%s'\n",
          $job->name, $job->ID, $job->PID, $output
      );
  }
  sub run { 
      foreach (qw( foo bar baz )) {
          my $job = MooseX::Workers::Job->new(
             name    => $_,
             command => sub { print "Hello World\n" },
             timeout => 30,
          );
          $_[0]->spawn( $job );
      }
      POE::Kernel->run();
  }
  no Moose;

  Manager->new()->run();   
  # bar(2,32423) said 'Hello World'
  # foo(1,32422) said 'Hello World'
  # baz(3,32424) said 'Hello World'

=head1 DESCRIPTION

MooseX::Workers::Job objects are convenient if you want to name each
L<MooseX::Workers> job, or if you want them to timeout (abort) 
after a certain number of seconds.

=head1 METHODS

The accessors, as well as:

=head2 is_coderef

Returns true if the command is some type of coderef, undef otherwise.

=cut

1;

