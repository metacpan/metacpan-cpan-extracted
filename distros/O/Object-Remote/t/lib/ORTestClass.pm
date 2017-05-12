package ORTestClass;

use Moo;

has counter => (is => 'rwp', default => sub { 0 });

sub increment { $_[0]->_set_counter($_[0]->counter + 1); }

sub pid { $$ }

sub call_callback {
  my ($self, $value, $cb) = @_;
  $cb->();
  return $value;
}

1;
