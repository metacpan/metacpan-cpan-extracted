use strict;
use warnings;
package Test::Abortable 0.003;
# ABSTRACT: subtests that you can die your way out of ... but survive

#pod =head1 OVERVIEW
#pod
#pod Test::Abortable provides a simple system for catching some exceptions and
#pod turning them into test events.  For example, consider the code below:
#pod
#pod   use Test::More;
#pod   use Test::Abortable;
#pod
#pod   use My::API; # code under test
#pod
#pod   my $API = My::API->client;
#pod
#pod   subtest "collection distinction" => sub {
#pod     my $result = $API->do_first_thing;
#pod
#pod     is($result->documents->first->title,  "The Best Thing");
#pod     isnt($result->documents->last->title, "The Best Thing");
#pod   };
#pod
#pod   subtest "document transcendence"   => sub { ... };
#pod   subtest "semiotic multiplexing"    => sub { ... };
#pod   subtest "homoiousios type vectors" => sub { ... };
#pod
#pod   done_testing;
#pod
#pod In this code, C<< $result->documents >> is a collection.  It has a C<first>
#pod method that will throw an exception if the collection is empty.  If that
#pod happens in our code, our test program will die and most of the other subtests
#pod won't run.  We'd rather that we only abort the I<subtest>.  We could do that 
#pod in a bunch of ways, like adding:
#pod
#pod   return fail("no documents in response") if $result->documents->is_empty;
#pod
#pod ...but this becomes less practical as the number of places that might throw
#pod these kinds of exceptions grows.  To minimize code that boils down to "and then
#pod stop unless it makes sense to go on," Test::Abortable provides a means to
#pod communicate, via exceptions, that the running subtest should be aborted,
#pod possibly with some test output, and that the program should then continue.
#pod
#pod Test::Abortable exports a C<L</subtest>> routine that behaves like L<the one in
#pod Test::More|Test::More/subtest> but will handle and recover from abortable
#pod exceptions (defined below).  It also exports C<L</testeval>>, which behaves
#pod like a block eval that only catches abortable exceptions.
#pod
#pod For an exception to be "abortable," in this sense, it must respond to a
#pod C<as_test_abort_events> method.  This method must return an arrayref of
#pod arrayrefs that describe the Test2 events to emit when the exception is caught.
#pod For example, the exception thrown by our sample code above might have a
#pod C<as_test_abort_events> method that returns:
#pod
#pod   [
#pod     [ Ok => (pass => 0, name => "->first called on empty collection") ],
#pod   ]
#pod
#pod It's permissible to have passing Ok events, or only Diag events, or multiple
#pod events, or none — although providing none might lead to some serious confusion.
#pod
#pod Right now, any exception that provides this method will be honored.  In the
#pod future, a facility for only allowing abortable exceptions of a given class may
#pod be added.
#pod
#pod =cut

use Test2::API 1.302075 (); # no_fork
use Sub::Exporter -setup => {
  exports => [ qw(subtest testeval) ],
  groups  => { default => [ qw(subtest testeval) ] },
};

#pod =func subtest
#pod
#pod   subtest "do some stuff" => sub {
#pod     do_things;
#pod     do_stuff;
#pod     do_actions;
#pod   };
#pod
#pod This routine looks just like Test::More's C<subtest> and acts just like it,
#pod too, with one difference: the code item passed in is executed in a block
#pod C<eval> and any exception thrown is checked for C<as_test_abort_events>.  If
#pod there's no exception, it returns normally.  If there's an abortable exception,
#pod the events are sent to the test hub and the subtest finishes normally.  If
#pod there's a non-abortable exception, it is rethrown.
#pod
#pod =cut

sub subtest {
  my ($name, $code) = @_;

  my $ctx = Test2::API::context();

  my $pass = Test2::API::run_subtest($name, sub {
    my $ok = eval { $code->(); 1 };

    my $ctx = Test2::API::context();

    if (! $ok) {
      my $error = $@;
      if (ref $error and my $events = eval { $error->as_test_abort_events }) {
        for (@$events) {
          my $e = $ctx->send_event(@$_);
          $e->set_meta(test_abort_object => $error)
        }
      } else {
        $ctx->release;
        die $error;
      }
    }

    $ctx->release;

    return;
  }, { no_fork => 1 });

  $ctx->release;

  return $pass;
}

#pod =func testeval
#pod
#pod   my $result = testeval {
#pod     my $x = get_the_x;
#pod     my $y = acquire_y;
#pod     return $x * $y;
#pod   };
#pod
#pod C<testeval> behaves like C<eval>, but only catches abortable exceptions.  If
#pod the code passed to C<testeval> throws an abortable exception C<testeval> will
#pod return false and put the exception into C<$@>.  Other exceptions are
#pod propagated.
#pod
#pod =cut

sub testeval (&) {
  my ($code) = @_;
  my $ctx = Test2::API::context();
  my @result;

  my $wa = wantarray;
  my $ok = eval {
    if    (not defined $wa) { $code->() }
    elsif (not         $wa) { @result = scalar $code->() }
    else                    { @result = $code->() }

    1;
  };

  if (! $ok) {
    my $error = $@;
    if (ref $error and my $events = eval { $error->as_test_abort_events }) {
      for (@$events) {
        my $e = $ctx->send_event(@$_);
        $e->set_meta(test_abort_object => $error)
      }

      $ctx->release;
      $@ = $error;
      return;
    } else {
      die $error;
    }
  }

  $ctx->release;
  return $wa ? @result : $result[0];
}

#pod =head1 EXCEPTION IMPLEMENTATIONS
#pod
#pod You don't need to use an exception class provided by Test::Abortable to build
#pod abortable exceptions.  This is by design.  In fact, Test::Abortable doesn't
#pod ship with any abortable exception classes at all.  You should just add a
#pod C<as_test_abort_events> where it's useful and appropriate.
#pod
#pod Here are two possible simple implementations of trivial abortable exception
#pod classes.  First, using plain old vanilla objects:
#pod
#pod   package Abort::Test {
#pod     sub as_test_abort_events ($self) {
#pod       return [ [ Ok => (pass => 0, name => $self->{message}) ] ];
#pod     }
#pod   }
#pod   sub abort ($message) { die bless { message => $message }, 'Abort::Test' }
#pod
#pod This works, but if those exceptions ever get caught somewhere else, you'll be
#pod in a bunch of pain because they've got no stack trace, no stringification
#pod behavior, and so on.  For a more robust but still tiny implementation, you
#pod might consider L<failures>:
#pod
#pod   use failures 'testabort';
#pod   sub failure::testabort::as_test_abort_events ($self) {
#pod     return [ [ Ok => (pass => 0, name => $self->msg) ] ];
#pod   }
#pod
#pod For whatever it's worth, the author's intent is to add C<as_test_abort_events>
#pod methods to his code through the use of application-specific Moose roles,
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Abortable - subtests that you can die your way out of ... but survive

=head1 VERSION

version 0.003

=head1 OVERVIEW

Test::Abortable provides a simple system for catching some exceptions and
turning them into test events.  For example, consider the code below:

  use Test::More;
  use Test::Abortable;

  use My::API; # code under test

  my $API = My::API->client;

  subtest "collection distinction" => sub {
    my $result = $API->do_first_thing;

    is($result->documents->first->title,  "The Best Thing");
    isnt($result->documents->last->title, "The Best Thing");
  };

  subtest "document transcendence"   => sub { ... };
  subtest "semiotic multiplexing"    => sub { ... };
  subtest "homoiousios type vectors" => sub { ... };

  done_testing;

In this code, C<< $result->documents >> is a collection.  It has a C<first>
method that will throw an exception if the collection is empty.  If that
happens in our code, our test program will die and most of the other subtests
won't run.  We'd rather that we only abort the I<subtest>.  We could do that 
in a bunch of ways, like adding:

  return fail("no documents in response") if $result->documents->is_empty;

...but this becomes less practical as the number of places that might throw
these kinds of exceptions grows.  To minimize code that boils down to "and then
stop unless it makes sense to go on," Test::Abortable provides a means to
communicate, via exceptions, that the running subtest should be aborted,
possibly with some test output, and that the program should then continue.

Test::Abortable exports a C<L</subtest>> routine that behaves like L<the one in
Test::More|Test::More/subtest> but will handle and recover from abortable
exceptions (defined below).  It also exports C<L</testeval>>, which behaves
like a block eval that only catches abortable exceptions.

For an exception to be "abortable," in this sense, it must respond to a
C<as_test_abort_events> method.  This method must return an arrayref of
arrayrefs that describe the Test2 events to emit when the exception is caught.
For example, the exception thrown by our sample code above might have a
C<as_test_abort_events> method that returns:

  [
    [ Ok => (pass => 0, name => "->first called on empty collection") ],
  ]

It's permissible to have passing Ok events, or only Diag events, or multiple
events, or none — although providing none might lead to some serious confusion.

Right now, any exception that provides this method will be honored.  In the
future, a facility for only allowing abortable exceptions of a given class may
be added.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 FUNCTIONS

=head2 subtest

  subtest "do some stuff" => sub {
    do_things;
    do_stuff;
    do_actions;
  };

This routine looks just like Test::More's C<subtest> and acts just like it,
too, with one difference: the code item passed in is executed in a block
C<eval> and any exception thrown is checked for C<as_test_abort_events>.  If
there's no exception, it returns normally.  If there's an abortable exception,
the events are sent to the test hub and the subtest finishes normally.  If
there's a non-abortable exception, it is rethrown.

=head2 testeval

  my $result = testeval {
    my $x = get_the_x;
    my $y = acquire_y;
    return $x * $y;
  };

C<testeval> behaves like C<eval>, but only catches abortable exceptions.  If
the code passed to C<testeval> throws an abortable exception C<testeval> will
return false and put the exception into C<$@>.  Other exceptions are
propagated.

=head1 EXCEPTION IMPLEMENTATIONS

You don't need to use an exception class provided by Test::Abortable to build
abortable exceptions.  This is by design.  In fact, Test::Abortable doesn't
ship with any abortable exception classes at all.  You should just add a
C<as_test_abort_events> where it's useful and appropriate.

Here are two possible simple implementations of trivial abortable exception
classes.  First, using plain old vanilla objects:

  package Abort::Test {
    sub as_test_abort_events ($self) {
      return [ [ Ok => (pass => 0, name => $self->{message}) ] ];
    }
  }
  sub abort ($message) { die bless { message => $message }, 'Abort::Test' }

This works, but if those exceptions ever get caught somewhere else, you'll be
in a bunch of pain because they've got no stack trace, no stringification
behavior, and so on.  For a more robust but still tiny implementation, you
might consider L<failures>:

  use failures 'testabort';
  sub failure::testabort::as_test_abort_events ($self) {
    return [ [ Ok => (pass => 0, name => $self->msg) ] ];
  }

For whatever it's worth, the author's intent is to add C<as_test_abort_events>
methods to his code through the use of application-specific Moose roles,

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 CONTRIBUTOR

=for stopwords Ricardo Signes

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
