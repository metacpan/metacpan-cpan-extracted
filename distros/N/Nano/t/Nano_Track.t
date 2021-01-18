use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Nano::Track

=cut

=tagline

Trackable Role

=cut

=abstract

Trackable Entity Role

=cut

=includes

method: decr
method: del
method: get
method: getpush
method: getset
method: getunshift
method: incr
method: merge
method: pop
method: poppush
method: push
method: set
method: shift
method: shiftunshift
method: unshift

=cut

=synopsis

  package Example;

  use Moo;

  extends 'Nano::Node';

  with 'Nano::Track';

  sub creator {
    my ($self, @args) = @_;
    return $self->getset('creator', @args);
  }

  sub touched {
    my ($self, @args) = @_;
    return $self->incr('touched');
  }

  package main;

  my $example = Example->new;

  # $example->touched;

=cut

=libraries

Nano::Types

=cut

=attributes

changed: ro, opt, Changes

=cut

=description

This package provides a transactional change-tracking role, useful for creating
a history of changes and/or preventing race conditions when saving data for
L<Nano::Node> entities. B<Note:> Due to conflicting method names, this role
cannot be used with the L<Nano::Stash> role.

=cut

=method decr

The decr method decrements the data associated with a specific key.

=signature decr

decr(Str $name) : Int

=example-1 decr

  my $example = Example->new;

  my $upvote = $example->decr('upvote');

=cut

=example-2 decr

  my $example = Example->new;

  $example->incr('upvote');
  $example->incr('upvote');
  $example->incr('upvote');

  my $upvote = $example->decr('upvote');

=cut

=method del

The del method deletes the data associated with a specific key.

=signature del

del(Str $name) : Any

=example-1 del

  my $example = Example->new;

  my $touched = $example->del('touched');

=cut

=example-2 del

  my $example = Example->new;

  $example->set('touched', 'monday');

  my $touched = $example->del('touched');

=cut

=method get

The get method return the data associated with a specific key.

=signature get

get($name) : Any

=example-1 get

  my $example = Example->new;

  my $profile = $example->get('profile');

=cut

=example-2 get

  my $example = Example->new;

  $example->set('profile', {
    nickname => 'demonstration',
  });

  my $profile = $example->get('profile');

=cut

=method getset

The getset method calls L</get> or L</set> based on the arguments provided.
Allows you to easily create method-based accessors.

=signature getset

getset(Str $name, Any @args) : Any

=example-1 getset

  my $example = Example->new;

  my $profile = $example->getset('profile', {
    nickname => 'demonstration',
  });

=example-2 getset

  my $example = Example->new;

  $example->getset('profile', {
    nickname => 'demonstration',
  });

  my $profile = $example->getset('profile');

=cut

=method incr

The incr method increments the data associated with a specific key.

=signature incr

incr(Str $name) : Int

=example-1 incr

  my $example = Example->new;

  my $upvote = $example->incr('upvote');

=cut

=example-2 incr

  my $example = Example->new;

  $example->incr('upvote');
  $example->incr('upvote');

  my $upvote = $example->incr('upvote');

=cut

=method merge

The merge method commits the data associated with a specific key to the channel
as a partial to be merged into any existing data.

=signature merge

merge(Str $name, HashRef $value) : HashRef

=example-1 merge

  my $example = Example->new;

  my $merge = $example->merge('profile', {
    password => 's3crets',
  });

=example-2 merge

  my $example = Example->new;

  $example->set('profile', {
    nickname => 'demonstration',
  });

  my $merge = $example->merge('profile', {
    password => 's3crets',
  });

=cut

=method pop

The pop method pops the data off of the stack associated with a specific key.

=signature pop

pop(Str $name) : Any

=example-1 pop

  my $example = Example->new;

  my $steps = $example->pop('steps');

=cut

=example-2 pop

  my $example = Example->new;

  $example->push('steps', '#1', '#2');

  my $steps = $example->pop('steps');

=cut

=method push

The push method pushes data onto the stack associated with a specific key.

=signature push

push(Str $name, Any @value) : ArrayRef[Any]

=example-1 push

  my $example = Example->new;

  my $arguments = $example->push('steps', '#1');

=cut

=example-2 push

  my $example = Example->new;

  my $arguments = $example->push('steps', '#1', '#2');

=cut

=method getpush

The getpush method calls L</push> or L</get> based on the arguments provided.
Allows you to easily create method-based accessors.

=signature getpush

getpush(Str $name, Any @args) : ArrayRef[Any] | Any

=example-1 getpush

  my $example = Example->new;

  my $steps = $example->getpush('steps');

=cut

=example-2 getpush

  my $example = Example->new;

  my $steps = $example->getpush('steps', '#1', '#2');

=cut

=method poppush

The poppush method calls L</push> or L</pop> based on the arguments provided.
Allows you to easily create method-based accessors.

=signature poppush

poppush(Str $name, Any @args) : ArrayRef[Any] | Any

=example-1 poppush

  my $example = Example->new;

  my $steps = $example->poppush('steps');

=cut

=example-2 poppush

  my $example = Example->new;

  $example->set('steps', ['#1', '#2', '#3']);

  my $steps = $example->poppush('steps', '#4');

=cut

=example-3 poppush

  my $example = Example->new;

  $example->set('steps', ['#1', '#2', '#3']);

  my $steps = $example->poppush('steps');

=cut

=method set

The set method commits the data associated with a specific key to the channel.

=signature set

set(Str $name, Any @args) : Any

=example-1 set

  my $example = Example->new;

  my $email = $example->set('email', 'try@example.com');

=cut

=example-2 set

  my $example = Example->new;

  my $email = $example->set('email', 'try@example.com', 'retry@example.com');

=cut

=method shift

The shift method shifts data off of the stack associated with a specific key.

=signature shift

shift(Str $name) : Any

=example-1 shift

  my $example = Example->new;

  my $steps = $example->shift('steps');

=cut

=example-2 shift

  my $example = Example->new;

  $example->set('steps', ['#1', '#2', '#3']);

  my $steps = $example->shift('steps');

=cut

=method unshift

The unshift method unshifts data onto the stack associated with a specific key.

=signature unshift

unshift(Str $name, Any @value) : ArrayRef[Any] | Any

=example-1 unshift

  my $example = Example->new;

  my $arguments = $example->unshift('steps');

=cut

=example-2 unshift

  my $example = Example->new;

  my $arguments = $example->unshift('steps', '#1', '#2');

=cut

=method shiftunshift

The shiftunshift method calls L</unshift> or L</shift> based on the arguments
provided. Allows you to easily create method-based accessors.

=signature shiftunshift

shiftunshift(Str $name, Any @args) : ArrayRef[Any] | Any

=example-1 shiftunshift

  my $example = Example->new;

  my $step = $example->shiftunshift('steps');

=cut

=example-2 shiftunshift

  my $example = Example->new;

  my $steps = $example->shiftunshift('steps', '#1', '#2');

=cut

=method getunshift

The getunshift method calls L</unshift> or L</get> based on the arguments
provided. Allows you to easily create method-based accessors.

=signature getunshift

getunshift(Str $name, Any @args) : ArrayRef[Any] | Any

=example-1 getunshift

  my $example = Example->new;

  my $step = $example->getunshift('steps');

=cut

=example-2 getunshift

  my $example = Example->new;

  $example->set('steps', ['#0']);

  my $step = $example->getunshift('steps', '#1', '#2');

=cut

package main;

BEGIN {
  $ENV{ZING_STORE} = 'Zing::Store::Hash';
}

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'decr', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, -1;

  $result
});

$subs->example(-2, 'decr', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 2;

  $result
});

$subs->example(-1, 'del', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-2, 'del', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'monday';

  $result
});

$subs->example(-1, 'get', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-2, 'get', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, {
    nickname => 'demonstration',
  };

  $result
});

$subs->example(-1, 'getset', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, {
    nickname => 'demonstration',
  };

  $result
});

$subs->example(-2, 'getset', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, {
    nickname => 'demonstration',
  };

  $result
});

$subs->example(-1, 'incr', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 1;

  $result
});

$subs->example(-2, 'incr', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 3;

  $result
});

$subs->example(-1, 'merge', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, {
    password => 's3crets',
  };

  $result
});

$subs->example(-2, 'merge', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, {
    nickname => 'demonstration',
    password => 's3crets',
  };

  $result
});

$subs->example(-1, 'pop', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-2, 'pop', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, '#2';

  $result
});

$subs->example(-1, 'push', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['#1'];

  $result
});

$subs->example(-2, 'push', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['#1', '#2'];

  $result
});

$subs->example(-1, 'getpush', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-2, 'getpush', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['#1', '#2'];

  $result
});

$subs->example(-1, 'poppush', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-2, 'poppush', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['#4'];

  $result
});

$subs->example(-3, 'poppush', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, '#3';

  $result
});

$subs->example(-1, 'set', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'try@example.com';

  $result
});

$subs->example(-2, 'set', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'try@example.com';

  $result
});

$subs->example(-1, 'shift', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-2, 'shift', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, '#1';

  $result
});

$subs->example(-1, 'unshift', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

$subs->example(-2, 'unshift', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['#1', '#2'];

  $result
});

$subs->example(-1, 'shiftunshift', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-2, 'shiftunshift', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['#1', '#2'];

  $result
});

$subs->example(-1, 'getunshift', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-2, 'getunshift', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['#1', '#2'];

  $result
});

ok 1 and done_testing;
