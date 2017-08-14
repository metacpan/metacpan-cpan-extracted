package PerlX::Generator::Invocation;

use strictures 2;
use Carp 'croak';
use Moo;

has _resume_with => (is => 'rw');

has code => (is => 'ro', required => 1);
has lexical_context => (is => 'ro', required => 1);
has start_args => (is => 'ro', required => 1);
has done => (is => 'rwp');
has return_value => (is => 'rwp');

sub next {
  my ($self, $value) = @_;

  return undef if $self->done;

  local our $Current = $self;
  local our $Sent_Value = $value;
  local our $Yielded_Value;

  # should set done here on exception
  $self->_set_return_value([ $self->code->($self->_resume_with ? () : @{$self->start_args}) ]);

  $self->_resume_with(undef);
  $self->_set_done(1);
  return undef;

  __GEN_YIELD:
  return $Yielded_Value;
}

sub error {
  my ($self, $error) = @_;

  die "Whut" if $self->done or not $self->_resume_with;
  local our $Sent_Error = $error;
  $self->next;
}

sub _gen_suspend {
  my ($self, $label, $yielded) = @_;
  our $Yielded_Value = $yielded;
  $self->_resume_with({
    label => $label,
    pad_values => $self->lexical_context->get_pad_values,
  });
  no warnings 'exiting'; goto __GEN_YIELD;
}

sub _gen_resume {
  my ($self) = @_;
  return unless my $state = $self->_resume_with;
  $self->lexical_context->set_pad_values($state->{pad_values});
  no warnings 'exiting'; no warnings 'deprecated'; goto $state->{label};
}

sub _gen_sent {
  if (our $Sent_Error) { croak $Sent_Error }
  our $Sent_Value
}

1;
