package PerlX::AsyncAwait::AsyncSub;

use strictures 2;
use PerlX::AsyncAwait::Invocation;
use Scalar::Util qw(weaken);
use Moo;

extends 'PerlX::Generator::Object';

sub invocation_class { 'PerlX::AsyncAwait::Invocation' }

around start => sub {
  my ($orig, $self, @args) = @_;
  my $inv = $self->$orig(@args)->step;
  my $f = $inv->completion_future;
  return $f if $f->is_ready;
  return $self->_tweaked_completion_future($inv);
};

sub _tweaked_completion_future {
  my $inv = $_[1];
  weaken($inv->{completion_future});
  $inv->completion_future->on_ready(sub { undef $inv });
  return $inv->completion_future;
}

1;
