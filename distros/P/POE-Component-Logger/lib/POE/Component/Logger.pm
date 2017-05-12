package POE::Component::Logger;
use strict;

use POE;
use Log::Dispatch::Config;

use vars qw($VERSION $DefaultLevel);

$VERSION = '1.10';

$DefaultLevel = 'warning';

sub spawn {
    my $class = shift;
    POE::Session->create(
        inline_states => {
            _start => \&_start_logger,
            _stop => \&_stop_logger,

            # Log at the $DefaultLevel
            log =>       sub { my @args = @_; $args[STATE] = $DefaultLevel; _poe_log(@args) },
            # Log at a specific level
            debug =>     \&_poe_log,
            info =>      \&_poe_log,
            notice =>    \&_poe_log,
            warning =>   \&_poe_log,
            error =>     \&_poe_log,
            critical =>  \&_poe_log,
            alert =>     \&_poe_log,
            emergency => \&_poe_log,
        },
        args => [ @_ ],
    );
}

sub _start_logger {
    my ($kernel, $heap, %args) = @_[KERNEL, HEAP, ARG0 .. $#_];

    $args{Alias} ||= 'logger';

    Log::Dispatch::Config->configure($args{ConfigFile});

    $heap->{_logger} = Log::Dispatch::Config->instance;
    $heap->{_alias} = $args{Alias};
    $kernel->alias_set($args{Alias});
}

sub _stop_logger {
    my ($kernel, $heap) = @_[KERNEL, HEAP];

    $kernel->alias_remove($heap->{_alias});
    delete $heap->{_logger};
}


sub _poe_log {
    my ($heap, $level, $arg0, @args) = @_[HEAP, STATE, ARG0..$#_];

    $heap->{_logger}->log(
        # The default level is the POE event name ($_[STATE])
        # (may be overriden in given hashref)
        level => $level,
        # If we get a HASHREF, expand it
        # If we get a scalar, concatenate args as the message
        (ref $arg0) ? (%{$arg0})
                    : (message => join('', $arg0, @args))
    );
}


sub log {
    my ($class, @args) = @_;
    POE::Kernel->post(logger => $DefaultLevel => @args);
}

*Logger::log = \&log;

1;
__END__

=head1 NAME

POE::Component::Logger - A POE logging class

=head1 SYNOPSIS

In your startup code somewhere:

  POE::Component::Logger->spawn(ConfigFile => 'log.conf');

And later in an event handler:

  Logger->log("Something happened!");

=head1 DESCRIPTION

POE::Component::Logger provides a simple logging component
that uses L<Log::Dispatch::Config> to drive it, allowing you
to log to multiple places at once (e.g. to STDERR and Syslog
at the same time) and also to flexibly define your logger's
output.

It is very simple to use, because it creates a Logger::log
method (yes, this is namespace corruption, so shoot me). If
you don't like this, feel free to post directly to your
logger as follows:

  $kernel->post('logger', 'log', "An error occurred: $!");

In fact you have to use that method if you pass an Alias
option to spawn (see below).

All logging is done in the background, so don't expect
immediate output - the output will only occur after control
goes back to the kernel so it can process the next event.

=head1 OPTIONS and METHODS

=head2 C<spawn>

The spawn class method can take two options. A required
B<ConfigFile> option, which specifies the location of the
config file as passed to L<Log::Dispatch::Config>'s
C<configure()> method (note that you can also use an object
here, see L<Log::Dispatch::Config> for more details). The
other available option is B<Alias> which you can use if you
wish to have more than one logger in your POE application.
Note though that if you specify an alias other than the
default 'logger' alias, you will not be able to use the
C<Logger-E<gt>log> shortcut, and will have to use direct
method calls instead.

=head2 C<Logger-E<gt>log> / C<POE::Component::Logger-E<gt>log>

This is used to perform a logging action. You may either
pass a string, or a hashref. If you pass in a string it
is logged at the level specified in
C<$POE::Component::Logger::DefaultLevel>, which is
'warning' by default. If you pass in a hashref it is expanded
as a hash and passed to Log::Dispatch's C<log()> method.

=head1 LOGGING STATES

The following states are available on the POE logging session:

=head2 C<log>

Same as C<Logger-E<gt>log()>, except you may use a different
alias if posting direct to the kernel, for example:

  $kernel->post( 'error.log', 'log', "Some error");
  $kernel->post( 'access.log', 'log', "Access Details");

=head2 C<debug>

And also C<notice>, C<info>, C<warning>, C<error>, C<critical>,
C<emergency> and C<alert>.

These states simply log at a different level. See
L<Log::Dispatch> for further details.

=head1 EXAMPLE CONFIG FILE

  # logs to screen (STDERR) and syslog
  dispatchers = screen syslog

  [screen]
  class = Log::Dispatch::Screen
  min_level = info
  stderr = 1
  format = %d %m %n

  [syslog]
  class = Log::Dispatch::Syslog
  min_level = warning


=head1 SUPPORT

You can look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-Logger>:
post bug report there.

=item * CPAN Ratings

L<http://cpanratings.perl.org/p/POE-Component-Logger>:
if you use this distibution, please add comments on your experience for other
users.

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Component-Logger/>

=item * GitHub

L<http://github.com/dolmen/POE-Component-Logger>:
the source code repository.

=back


=head1 AUTHORS

Matt Sergeant, C<matt@sergeant.org>.

Olivier MenguE<eacute>, C<dolmen@cpan.org>.

=head1 COPYRIGHT & LICENSE

Copyright E<copy> 2002 Matt Sergeant.

Copyright E<copy> 2010 Olivier MenguE<eacute>.

This is free software. You may use it and redistribute it
under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item *

L<Log::Dispatch>

=item *

L<Log::Dispatch::Config>

=item *

L<AppConfig>

=item *

L<POE>

=back

=cut

