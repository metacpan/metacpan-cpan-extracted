package PerlX::AsyncAwait::Invocation;

use strictures 2;
use Future;
use curry::weak;
use Moo;

extends 'PerlX::Generator::Invocation';

has completion_future => (
  is => 'lazy',
  builder => sub { Future->new },
);

has awaiting_future => (is => 'rwp');

sub step {
  my ($self, $ready) = @_;
  local our $Ready_Future = $ready;
  my $f;
  unless (eval { $f = $self->next; 1 }) {
    $self->completion_future->fail($@);
    $self->_resume_with(undef);
    $self->_set_done(1);
    return $self;
  }
  if ($self->done) {
    $self->completion_future->done(@{$self->return_value});
    return $self;
  }
  $f->on_ready($self->curry::step);
  $self->_set_awaiting_future($f);
  return $self;
}

around _gen_suspend => sub {
  my ($orig, $self, $label, $f) = @_;
  if ($f->is_ready) {
    our $Ready_Future = $f;
    return;
  }
  $self->$orig($label, $f);
};

sub _gen_sent {
  my $f = our $Ready_Future;
  if ($f->is_failed) {
    die $f->failure;
  }
  $f->get;
}

1;
