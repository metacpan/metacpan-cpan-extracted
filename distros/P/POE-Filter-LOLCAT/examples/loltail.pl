use strict;
use POE qw(Wheel::FollowTail Filter::Stackable Filter::Line Filter::LOLCAT);

$|=1;

die "You must provide a file to monitor\n" unless scalar @ARGV;

my $filename = shift @ARGV;

POE::Session->create(
  package_states => [
	'main' => [qw(_start _input _error)],
  ],
  args => [ $filename ],
);

$poe_kernel->run();
exit 0;

sub _start {
  my ($kernel,$heap,$file) = @_[KERNEL,HEAP,ARG0];
  my $filter = POE::Filter::Stackable->new(
	Filters => [ POE::Filter::Line->new(), POE::Filter::LOLCAT->new() ],
  );
  $heap->{wheel} = POE::Wheel::FollowTail->new(
	Filename     => $file,
	Filter       => $filter,
	PollInterval => 1,
	InputEvent   => '_input',
	ErrorEvent   => '_error',
  );
  return;
}

sub _input {
  print $_[ARG0], "\n";
  return;
}

sub _error {
  my ($operation, $errnum, $errstr, $wheel_id) = @_[ARG0..ARG3];
  warn "Wheel $wheel_id generated $operation error $errnum: $errstr\n";
  return;
}
