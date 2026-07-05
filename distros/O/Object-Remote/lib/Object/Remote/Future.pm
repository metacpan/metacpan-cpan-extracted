package Object::Remote::Future;

use strict;
use warnings;
use base qw(Exporter);

use Object::Remote::Logging qw( :log router );

BEGIN { router()->exclude_forwarding }

use Future;

our @EXPORT = qw(future await_future await_all);

sub future (&;$) {
  my $f = $_[0]->(Object::Remote->current_loop->new_future);
  return $f if ((caller(1+($_[1]||0))||'') eq 'start');
  await_future($f);
}

sub await_future {
  my $f = shift;
  Object::Remote->current_loop->await($f);
  return wantarray ? $f->get : ($f->get)[0];
}

sub await_all {
  log_trace { my $l = @_; "await_all() invoked with '$l' futures to wait on" };
  Object::Remote->current_loop->await_all(@_);
  map $_->get, @_;
}

package # hide from PAUSE
    start;

our $start = sub { my ($obj, $call) = (shift, shift); $obj->$call(@_); };

sub AUTOLOAD {
  my $invocant = shift;
  my ($method) = our $AUTOLOAD =~ /^start::(.+)$/;
  my $res;
  unless (eval { $res = $invocant->$method(@_); 1 }) {
    my $f = Object::Remote->current_loop->new_future;
    $f->fail($@);
    return $f;
  }
  unless (Scalar::Util::blessed($res) and $res->isa('Future')) {
    my $f = Object::Remote->current_loop->new_future;
    $f->done($res);
    return $f;
  }
  return $res;
}

package # hide from PAUSE
    maybe;

sub start {
  my ($obj, $call) = (shift, shift);
  if ((caller(1)||'') eq 'start') {
    $obj->$start::start($call => @_);
  } else {
    $obj->$call(@_);
  }
}

package # hide from PAUSE
    maybe::start;

sub AUTOLOAD {
  my $invocant = shift;
  my ($method) = our $AUTOLOAD =~ /^maybe::start::(.+)$/;
  $method = "start::${method}" if ((caller(1)||'') eq 'start');
  $invocant->$method(@_);
}

package # hide from PAUSE
    then;

sub AUTOLOAD {
  my $invocant = shift;
  my ($method) = our $AUTOLOAD =~ /^then::(.+)$/;
  my @args = @_;
  return $invocant->then(sub {
    my ($obj) = @_;
    return $obj->${\"start::${method}"}(@args);
  });
}

1;

=head1 NAME

Object::Remote::Future - Asynchronous calling for L<Object::Remote>

=head1 LAME

Shipping prioritised over writing this part up. Blame mst.

=cut
