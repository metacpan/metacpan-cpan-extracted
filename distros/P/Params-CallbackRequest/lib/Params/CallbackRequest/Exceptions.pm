package Params::CallbackRequest::Exceptions;

use strict;
use vars qw($VERSION);
$VERSION = '1.20';

use Exception::Class (
    'Params::Callback::Exception' => {
        description => 'Params::Callback exception',
        alias       => 'throw_cb'
    },

    'Params::Callback::Exception::InvalidKey' => {
        isa         => 'Params::Callback::Exception',
        description => 'No callback found for callback key',
        alias       => 'throw_bad_key',
        fields      => [qw(callback_key)]
    },

    'Params::Callback::Exception::Execution' => {
        isa         => 'Params::Callback::Exception',
        description => 'Error thrown by callback',
        alias       => 'throw_cb_exec',
        fields      => [qw(callback_key callback_error)]
    },

    'Params::Callback::Exception::Params' => {
        isa         => 'Params::Callback::Exception',
        description => 'Invalid parameter',
        alias       => 'throw_bad_params',
        fields      => [qw(param)]
    },

    'Params::Callback::Exception::Abort' => {
        isa         => 'Params::Callback::Exception',
        fields      => [qw(aborted_value)],
        alias       => 'throw_abort',
        description => 'a callback called abort()'
    },
);

sub import {
    my ($class, %args) = @_;

    my $caller = caller;
    if ($args{abbr}) {
        foreach my $name (@{$args{abbr}}) {
            no strict 'refs';
            die "Unknown exception abbreviation '$name'"
                unless defined &{$name};
            *{"${caller}::$name"} = \&{$name};
        }
    }

    no strict 'refs';
    *{"${caller}::isa_cb_exception"} = \&isa_cb_exception;
    *{"${caller}::rethrow_exception"} = \&rethrow_exception;
}

sub isa_cb_exception ($;$) {
    my ($err, $name) = @_;
    return unless defined $err;

    my $class = "Params::Callback::Exception";
    $class .= "::$name" if $name;
    return UNIVERSAL::isa($err, $class);
}

sub rethrow_exception ($) {
    my $err = shift or return;
    $err->rethrow if UNIVERSAL::can($err, 'rethrow');
    die $err if ref $err;
    Params::Callback::Exception->throw(error => $err);
}

1;
__END__

=head1 NAME

Params::CallbackRequest::Exceptions - Parameter callback exception definitions

=head1 SYNOPSIS

  use Params::CallbackRequest::Exceptions;
  Params::Callback::Exception::Execution->throw("Whoops!");

  use Params::CallbackRequest::Exceptions abbr => [qw(throw_cb_exec)];
  throw_cb_exec "Whoops!";

=head1 DESCRIPTION

This module creates the exceptions used by Params::CallbackRequest and
Params::Callback. The exceptions are subclasses of Exception::Class::Base,
created by the interface defined by Exception::Class.

=head1 INTERFACE

=head2 Exported Functions

This module exports two functions by default.

=head3 C<isa_cb_exception>

  eval { something_that_dies() };
  if (my $err = $@) {
      if (isa_cb_exception($err, 'Abort')) {
          print "All hands abandon ship!";
      } elsif (isa_cb_exception($err)) {
          print "I recall an exceptional fault.";
      } else {
          print "No clue.";
      }
  }

This function takes a single argument and returns true if it's a
Params::Callback::Exception object. A second, optional argument can be used to
identify a particular subclass of Params::Callback::Exception.

=head3 C<rethrow_exception>

  eval { something_that_dies() };
  if (my $err = $@) {
      # Do something intelligent, and then...
      rethrow_exception($err);
  }

This function takes an exception as its sole argument and rethrows it. If the
argument is an object that C<can('throw')>, such as any subclass of
Exception::Class, then C<rethrow_exception()> will call its rethrow method. If
not, but the argument is a reference, C<rethrow_exception()> will simply die
with it. And finally, if the argument is not a reference at all,
C<rethrow_exception()> will throw a new Params::Callback::Exception exception
with the argument used as the exception error message.

=head3 Abbreviated Exception Functions

Each of the exception classes created by Params::CallbackRequest::Exceptions has a
functional alias for its throw class method. These may be imported by passing
an array reference of the names of the abbreviated functions to import via the
C<abbr> parameter:

  use Params::CallbackRequest::Exceptions abbr => [qw(throw_cb_exec)];

The names of the abbreviated functions are:

=over 4

=item throw_cb

Params::Callback::Exception

=item throw_bad_key

Params::Callback::Exception::InvalidKey

=item throw_cb_exec

Params::Callback::Exception::Execution

=item throw_bad_params

Params::Callback::Exception::Params

=item throw_abort

Params::Callback::Exception::Abort

=back

=head2 Exception Classes

The exception classes created by Params::Callback::Exception are as follows:

=head3 Params::Callback::Exception

This is the base class for all Params::Callback exception classes. Its
functional alias is C<throw_cb>.

=head3 Params::Callback::Exception::InvalidKey

Params::CallbackRequest throws this exception when a callback key in the parameter
hash passed to C<new()> has no corresponding callback. In addition to the
attributes offered by Exception::Class::Base, this class also features the
attribute C<callback_key>. Use the C<callback_key()> accessor to see what
callback key triggered the
exception. Params::Callback::Exception::InvalidKey's functional alias is
C<throw_bad_key>.

=head3 Params::Callback::Exception::Execution

This is the exception thrown by Params::CallbackRequest's default exception
handler when a callback subroutine or method dies. In addition to the
attributes offered by Exception::Class::Base, this class also features the
attributes C<callback_key>, which corresponds to the parameter key that
triggered the callback, and C<callback_error> which is the error thrown by the
callback subroutine or method. Params::Callback::Exception::Execution's
functional alias is C<throw_cb_exec>.

=head3 Params::Callback::Exception::Params

This is the exception thrown when an invalid parameter is passed to
Params::CallbackRequest's or Params::Callback's C<new()> constructors. Its
functional alias is C<throw_bad_params>.

=head3 Params::Callback::Exception::Abort

This is the exception thrown by Params::Callback's C<abort()> method.
functional alias is C<throw_cb>. In addition to the attributes offered by
Exception::Class::Base, this class also features the attribute
C<aborted_value> attribute. Use the C<aborted_value()> accessor to see what
value was passed to C<abort()>. Params::Callback::Exception::Abort's
functional alias is C<throw_abort>.

=head1 SEE ALSO

L<Params::Callback|Params::Callback> is the base class for all callback
classes.

L<Params::CallbackRequest|Params::CallbackRequest> sets up callbacks for execution.

L<Exception::Class|Exception::Class> defines the interface for the exception
classes created here.

=head1 SUPPORT

This module is stored in an open L<GitHub
repository|http://github.com/theory/params-callbackrequest/>. Feel free to
fork and contribute!

Please file bug reports via L<GitHub
Issues|http://github.com/theory/params-callbackrequest/issues/> or by sending
mail to
L<bug-params-callbackrequest@rt.cpan.org|mailto:bug-params-callbackrequest@rt.cpan.org>.

=head1 AUTHOR

David E. Wheeler <david@justatheory.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2011 David E. Wheeler. Some Rights Reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
