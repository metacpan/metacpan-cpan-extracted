#!/usr/bin/perl -w

use FileHandle;
use POE qw(Filter::Stackable Filter::CSV Filter::Line Wheel::ReadWrite);

POE::Session->create(
	inline_states => { _start => \&start_test,
			   _stop  => \&stop_test,
			   f_input => \&file_input,
			   f_error => \&file_error,
	},
);

$poe_kernel->run();
exit 0;

sub start_test {
  my ($kernel,$heap) = @_[KERNEL,HEAP];

  $heap->{filter} = POE::Filter::Stackable->new();

  $heap->{filter}->push( POE::Filter::Line->new(),
			 POE::Filter::CSV->new(),
  );

  my $fh = new FileHandle "< test.csv";

  $heap->{wheel} = POE::Wheel::ReadWrite->new(
	Handle => $fh,
	InputEvent => 'f_input',
	ErrorEvent => 'f_error',
	Filter => $heap->{filter},
  );
  return;
}

sub stop_test {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  delete $heap->{wheel};
  return;
}

sub file_error {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  warn join(' ', @_[ARG0..$#_]), "\n";
  delete $heap->{wheel};
  return;
}

sub file_input {
  my ($kernel,$heap,$input) = @_[KERNEL,HEAP,ARG0];

  foreach my $col ( @$input ) {
	print "$col\n";
  }
  return;
}
