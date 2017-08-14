package PerlX::Generator::Object;

use strictures 2;
use Lexical::Context;
use PerlX::Generator::Invocation;
use Moo;

use overload '&{}' => sub { my $self = shift; sub { $self->start(@_) } };

has code => (is => 'ro', required => 1);

has lexical_context => (is => 'lazy', builder => sub {
  my ($self) = @_;
  return Lexical::Context->new(code => $self->code);
});

sub invocation_class { 'PerlX::Generator::Invocation' }

sub start {
  my ($self, @args) = @_;
  return $self->invocation_class->new(
    code => $self->code,
    lexical_context => $self->lexical_context,
    start_args => \@args
  );
}

1;
