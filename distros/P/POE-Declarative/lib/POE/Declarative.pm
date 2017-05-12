use strict;
use warnings;

package POE::Declarative;
BEGIN {
  $POE::Declarative::VERSION = '0.09';
}

require Exporter;
our @ISA = qw( Exporter );

use Carp;
use POE;
use Scalar::Util qw/ blessed reftype /;

our @EXPORT = qw(
    call delay post yield

    get

    on run
);

=head1 NAME

POE::Declarative - write POE applications without the mess

=head1 VERSION

version 0.09

=head1 SYNOPSIS

  use POE;
  use POE::Declarative;

  on _start => run {
      yield 'count_to_10';
  };

  on count_to_10 => run {
      for ( 1 .. 10 ) {
          yield say => $_;
      }
  };

  on say => run {
      print get(ARG0);
  };

  POE::Declarative->setup;
  POE::Kernel->run;

=head1 DESCRIPTION

Taking the lessons learned from writing dispatchers and templates in L<Jifty> and L<Template::Declare>, I've applied the same declarative language to L<POE>. The goal is to make writing a POE application less painful so that I can concentrate on the more important aspects of my programming.

=head1 DECLARATIONS

=head2 on STATE => CODE

=head2 on [ STATE1, STATE2, ... ] => CODE

Use the C<on> rule to specify what code to run on a given state (or states). The usual way to say this is:

  on _start => run { ... };

But you could also say:

  on _start => sub { ... };

or:

  on _start => run _start_handler;

or:

  on _start => \&_start_handler;

=head3 MULTIPLE STATES FOR A SINGLE HANDLER

You can also specify multiple states for a single subroutine:

  on [ 'say', 'yell', 'whisper' ] => run { ... };

This has the same behavior as setting the same subroutine for each of these individually.

=head3 STATE HANDLER METHODS

Each state is also placed as a method within the current package. This method will be prefixed with "_poe_declarative_" to keep it from conflicting with any other methdos you've defined. So, you can define:

  sub _start { ... }

  on _start => \&_start;

This will then result in an additional method named "C<_poe_declarative__start>" being added to your package. These method names are then passed as state handlers to the L<POE::Session>.

=head3 MULTIPLE HANDLERS PER STATE

You may have multiple handlers for each state with L<POE::Declarative>. If you have two calls to C<on()> for the same state name, both of those handlers will be run when that state is entered by L<POE>. If you are using L<POE::Declarative::Mixin> your mixin classes and your main class may all define a handler for a given state and all handlers will be run. 

  package X;
  use base qw/ POE::Declarative::Mixin /;

  use POE::Declarative;

  on foo => run { print "X" };

  package Y;
  use base qw/ POE::Declarative::Mixin /;

  use POE::Declarative;

  on foo => run { print "Y" };

  package Z;
  use POE::Declarative;
  use X;
  use Y;

  on foo => run { print "Z\n" };
  on _start => run { yield 'foo' };

  POE::Declarative->setup;
  POE::Kernel->run;

In the example above, the output could be:

  XYZ

The order multiple handlers will run in is not (as of this writing) completely explicit. However, the primary package's handlers will be run last after all mixins have run. Also, the order the handlers is defined within a package will be preserved. Thus, if you define two handlers for the same state within the same package, the one defined first will be run first and the one defined second will be run second.

Because of these, the output from the previous example might also be:

 YXZ

If you use L</call> to synchronously activate a state and use the return value. It will be set to the return value of the last handler run in the main package.

=cut

sub on($$) {
    my $state = shift;
    my $code  = shift;

    croak qq{"on" expects a code reference as the second argument, }
         .qq{found $code instead} 
            unless ref $code and reftype $code eq 'CODE';

    my $session = POE::Kernel->get_active_session;
    my $package;

    # The kernel is not yet running/not in an active session
    if ($session->isa('POE::Kernel')) {

        # Normally, the caller is good enough
        $package = caller;

        # DEEP MAGIC!!! BEWARE OF THE DWIMMERY!!!
        #
        # However, if we're in a mixin declaring a state using some sort of
        # fancy helper subroutine, we need to try and put that declared state
        # into the calling class not in the mixin where it fouls the mixin's
        # declaration and doesn't make it into the session configuration
        # properly. See t/dynamic-late-mixin-states.t for an example of the
        # kind of situation where this comes up.
        my $caller = 1;
        while (defined $package && $package->isa('POE::Declarative::Mixin')) {
            $package = caller($caller++);
        }

        # Fallback position in case we get confused
        $package = caller unless defined $package;
    }

    # The POE kernel is running and in a session
    else {
        # Try to guess the package from the session if in a POE::Declarative
        # handler, or fallback to the caller if not, which may be bad. By using
        # the state's OBJECT, this should magically handle this work in mixins
        # as well!
        my $object = get(OBJECT) || caller;
        $package = ref $object || $object;
    }

    # Using on [ qw/ x y z / ] => ... syntax
    if (ref $state and reftype $state eq 'ARRAY') {
        for my $individual_state (@$state) {
            _declare_method($package, $individual_state, $code);
        }
    }

    # Using on x => ... syntax
    else {
        _declare_method($package, $state, $code);
    }
}

sub _declare_method {
    my $package = shift;
    my $state   = shift;
    my $code    = shift;

    my $states   = _states($package);
    my $handlers = _handlers($package);

    my $method = '_poe_declarative_' . $state;
    $states->{ $state } = $method;
    push @{ $handlers->{ $state }{ $package } }, $code;

    {
        no strict 'refs';
        no warnings 'redefine';
        *{ $package . '::' . $method } = sub { 
            _args(@_); 
            _handle_state(@_);
        };
    }

    # Check if the system is running or not
    my $session = POE::Kernel->get_active_session;

    # We're in an active session, make sure the kernel is updated
    unless ($session->isa('POE::Kernel')) {
        POE::Kernel->state($state, $package, $method);
    }
}

sub _handle_state {
    my $self     = $_[OBJECT];
    my $state    = $_[STATE];
    my $package  = ref $self || $self;

    my $all_handlers = _handlers($package);
    my $my_handlers  = $all_handlers->{ $state };

    my ($result, @result);
    my @handler_packages 
        = sort { $a eq $package ?  1 # put this package at the end
               : $b eq $package ? -1
               :                   0 } keys %$my_handlers;
    for my $handler_package (@handler_packages) {
        my $codes = $my_handlers->{ $handler_package };

        for my $code (@$codes) {
            if (wantarray) {
                @result = $code->(@_);
            }
            elsif (defined wantarray) {
                $result = $code->(@_);
            }
            else {
                $code->(@_);
            }
        }
    }

    return wantarray ? @result : $result;
}

=head2 run CODE

This is mostly a replacement keyword for C<sub> because:

  on _start => run { ... };

reads better than:

  on _start => sub { ... };

=cut

sub run(&) { $_[0] }

=head1 HELPERS

In addition to providing the declarative syntax the system also provides some helpers to shorten up the guts of your POE applications as well.

=head2 get INDEX

Rather than doing this (which you can still do inside your handlers):

  my ($kernel, $heap, $session, $flam, $floob, $flib)
      = @_[KERNEL, HEAP, SESSION, ARG0, ARG1, ARG2];

You can use the C<get> subroutine for a short hand, like:

  my $kernel = get KERNEL;
  get(HEAP)->{flubber} = 'doo';

If you don't like C<get>, don't use it. As I said, the code above will run exactly as you're used to if you're used to writing regular POE applications.

=cut

sub get($) {
    my $pos = shift;
    my $package = caller;
    return _args()->[ $pos ];
}

=head2 call SESSION, STATE, ARGS

This is just a shorthand for L<POE::Kernel/call>.

=cut

sub call($$;@) {
    POE::Kernel->call( @_ );
}

=head2 delay STATE, SECONDS, ARGS

This is just a shorthand for L<POE::Kernel/delay>.

=cut

sub delay($;$@) {
    POE::Kernel->delay( @_ );
}

=head2 post SESSION, STATE, ARGS

This is just a shorthand for L<POE::Kernel/post>.

=cut

sub post($$;@) {
    POE::Kernel->post( @_ );
}

=head2 yield STATE, ARGS

This is just a shorthand for L<POE::Kernel/yield>.

=cut

sub yield($;@) {
    POE::Kernel->yield( @_ );
}

=head1 SETUP METHODS

The setup methods setup your session and such and generally get your session read for the POE kernel to do its thing.

=head2 setup [ CLASS [ , HEAP ] ]

Typically, this is called via:

  POE::Declarative->setup;

If called within the package defining the session, this should DWIM nicely. However, if you call it from outside the package (for example, you have several session packages that are then each set up from a central loader), you can also run:

  POE::Declarative->setup('MyPOEApp::Component::FlabbyBo');

And finally, the third form is to pass a blessed reference of that class in, which will become the C<OBJECT> argument to all your states (rather than it just being the name of the class).

  my $flabby_bo = MyPOEApp::Component::FlabbyBo->new;
  POE::Declarative->setup($flabby_bo);

You may also specify a second argument that will be used to setup the L<POE::Session> heap. If not given, the C<HEAP> argument defaults to an empty hash reference.

=cut

our $_POE_DECLARATIVE_ARGS;
sub _args {
    $_POE_DECLARATIVE_ARGS = [ @_ ] if scalar(@_) > 0;
    return $_POE_DECLARATIVE_ARGS || [];
}

sub _handlers {
    my $package = shift || caller(1);

    no strict 'refs';
    return scalar (${ $package . '::_POE_DECLARATIVE_HANDLERS' } ||= {});
}

sub _states {
    my $package = shift || caller(1);

    no strict 'refs';
    return scalar (${ $package . '::_POE_DECLARATIVE_STATES' } ||= {});
}

sub setup {
    my $class   = shift;

    unshift @_, $class if defined $class and $class ne __PACKAGE__;

    my $package = shift || caller;
    my $heap    = shift || {};

    # Use object states
    if (blessed $package) {
        POE::Session->create(
            object_states => [ $package => _states(blessed $package) ],
            heap => $heap,
        );
    }

    # Use package states
    else {
        POE::Session->create(
            package_states => [ $package => _states($package) ],
            heap => $heap,
        );
    }
}

=head1 SEE ALSO

L<POE>

=head1 AUTHORS

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc. All Rights Reserved.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;