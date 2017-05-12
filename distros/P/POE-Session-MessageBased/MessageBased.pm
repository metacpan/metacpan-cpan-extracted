# License and documentation are after __END__.

# This is prototype code.  It rummages around in its base class'
# namespace for constants, among other unsavory things.

# Artur Bergman suggests keeping a static Message object in the
# Session itself, and reusing that instead of building and destroying
# messages each time.  That could be a little faster.

package POE::Session::MessageBased;

use warnings;
use strict;

use vars qw($VERSION);
$VERSION = '0.111';

use POE;
use base qw(POE::Session);
use POSIX qw(ENOSYS);

sub _invoke_state {
	my ($self, $source_session, $state, $etc, $file, $line) = @_;

	# Trace the state invocation if tracing is enabled.

	if ($self->[POE::Session::SE_OPTIONS]->{+POE::Session::OPT_TRACE}) {
		warn(
			$POE::Kernel::poe_kernel->ID_session_to_id($self),
			" -> $state (from $file at $line)\n"
		);
	}

	# The desired destination state doesn't exist in this session.
	# Attempt to redirect the state transition to _default.

	unless (exists $self->[POE::Session::SE_STATES]->{$state}) {

		# There's no _default either; redirection's not happening today.
		# Drop the state transition event on the floor, and optionally
		# make some noise about it.

		unless (
			exists
			$self->[POE::Session::SE_STATES]->{+POE::Session::EN_DEFAULT}
		) {
			$! = ENOSYS;
			if ($self->[POE::Session::SE_OPTIONS]->{+POE::Session::OPT_DEFAULT}) {
				warn(
					"a '$state' state was sent from $file at $line to session ",
					$POE::Kernel::poe_kernel->ID_session_to_id($self),
					", but session ",
					$POE::Kernel::poe_kernel->ID_session_to_id($self),
					" has neither that state nor a _default state to handle it\n"
				);
			}
			return undef;
		}

		# If we get this far, then there's a _default state to redirect
		# the transition to.  Trace the redirection.

		if ($self->[POE::Session::SE_OPTIONS]->{+POE::Session::OPT_TRACE}) {
			warn(
				$POE::Kernel::poe_kernel->ID_session_to_id($self),
				" -> $state redirected to _default\n"
			);
		}

		# Transmogrify the original state transition into a corresponding
		# _default invocation.

		$etc   = [ $state, $etc ];
		$state = POE::Session::EN_DEFAULT;
	}

	# If we get this far, then the state can be invoked.  So invoke it
	# already!

	# Inline states are invoked this way.

	if (ref($self->[POE::Session::SE_STATES]->{$state}) eq 'CODE') {
		my $message = POE::Session::Message->new(
			undef,                          # object
			$self,                          # session
			$POE::Kernel::poe_kernel,       # kernel
			$self->[POE::Session::SE_NAMESPACE], # heap
			$state,                         # state
			$source_session,                # sender
			undef,                          # unused #6
			$file,                          # caller file name
			$line,                          # caller file line
			$etc                            # args
		);

		return $self->[POE::Session::SE_STATES]->{$state}->($message, @$etc);
	}

	# Package and object states are invoked this way.

	my ($object, $method) = @{$self->[POE::Session::SE_STATES]->{$state}};
	my $message = POE::Session::Message->new(
		$object,                        # object
		$self,                          # session
		$POE::Kernel::poe_kernel,       # kernel
		$self->[POE::Session::SE_NAMESPACE], # heap
		$state,                         # state
		$source_session,                # sender
		undef,                          # unused #6
		$file,                          # caller file name
		$line,                          # caller file line
		$etc                            # args
	);

	# Package/object are implied.
	return $object->$method($message, @$etc);
}

package POE::Session::Message;

use POE::Session;

sub new {
	my $class = shift;
	my $self = bless [ @_ ], $class;
	return $self;
}

sub object      { $_[0]->[OBJECT]      }
sub session     { $_[0]->[SESSION]     }
sub kernel      { $_[0]->[KERNEL]      }
sub heap        { $_[0]->[HEAP]        }
sub state       { $_[0]->[STATE]       }
sub sender      { $_[0]->[SENDER]      }
sub caller_file { $_[0]->[CALLER_FILE] }
sub caller_line { $_[0]->[CALLER_LINE] }
sub args        { @{$_[0]->[ARG0]}     }

1;

__END__

=head1 NAME

POE::Session::MessageBased - a message-based (not @_ based) POE::Session

=head1 SYNOPSIS

	use POE::Kernel;
	use POE::Session::MessageBased;

	POE::Session::MessageBased->create(
		inline_states => {
			_start => sub {
				my $message = shift;
				print "Started.\n";
				$message->kernel->yield( count => 2 );
			},
			count => sub {
				my ($message, $count) = @_;
				print "Counted to $count.\n";
				if ($count < 10) {
					$message->kernel->yield( count => ++$count );
				}
			},
			_stop => sub {
				print "Stopped.\n";
			}
		},
	);

	POE::Kernel->run();

=head1 DESCRIPTION

POE::Session::MessageBased exists mainly to replace @_[KERNEL, etc.]
with message objects that encapsulate various aspects of each event.
It also exists as an example of a subclassed POE::Session, in case
someone wants to create new callback or Session semantics.

People generally balk at the @_[KERNEL, etc.] calling convention that
POE uses by default.  The author defends the position that this
calling convention is a simple combination of common Perl features.
Interested people can read
http://poe.perl.org/?POE_FAQ/calling_convention for a more detailed
account.

Anyway, POE::Session::MessageBased subclasses POE::Session and works
almost identically to it.  The major change is the way event handlers
(states) are called.

Inline (coderef) handlers gather their parameters like this.

	my ($message, @args) = @_;

Package and object-oriented handlers receive an additional parameter
representing the package or object.  This is part of the common
calling convention that Perl uses.

	my ($package, $message, @args) = @_;  # Package states.
	my ($self, $message, @args) = @_;     # Object states.

The $message parameter is an instance of POE::Session::Message, which
is not documented elsewhere.  POE::Session::Message encapsulates every
POE parameter and provides accessors for them.

	POE::Session             POE::Session::MessageBased
	------------------------ -----------------------------------
	$_[OBJECT]               $package, or $self
	$_[SESSION]              $message->session
	$_[KERNEL]               $message->kernel
	$_[HEAP]                 $message->heap
	$_[STATE]                $message->state
	$_[SENDER]               $message->sender
	$_[CALLER_FILE]          $message->caller_file
	$_[CALLER_LINE]          $message->caller_line
	@_[ARG0..$#_]            $message->args (in list context)

You do not need to use POE::Session::Message yourself.  It is included
in POE::Session::MessageBased itself.

=head1 BUGS

$message->args() always returns a list: @_[ARG0..$#_].  It would be
nice to return a list reference in scalar context.

=head1 BUG TRACKER

https://rt.cpan.org/Dist/Display.html?Status=Active&Queue=POE-Session-MessageBased

=head1 REPOSITORY

http://github.com/rcaputo/poe-session-messagebased
http://gitorious.org/poe-session-messagebased

=head1 OTHER RESOURCES

http://search.cpan.org/dist/POE-Session-MessageBased/

=head1 AUTHOR & LICENSE

POE::Session::MessageBased is Copyright 2002-2010 by Rocco Caputo.
All rights are reserved.  POE::Session::MessageBased is free software;
you may redistribute it and/or modify it under the same terms as Perl
itself.

=cut
