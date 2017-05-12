package MojoX::Log::Log4perl;
use Mojo::Base 'Mojo::EventEmitter';
use Log::Log4perl;

use warnings;
use strict;

our $VERSION = '0.11';

has history          => sub { [] };
has max_history_size => 10;

my $format_warning_was_shown = 0;

# development notes: Mojo::Log provides 'path' 'handle' and 'format'
# to handle log location and formatting. Those make no sense in a Log4perl
# environment (where you can set appenders as you wish) so they are
# not implemented here; 'format' simply returns the passed-in strings joined by
# newlines as otherwise Mojo::Log complains (RT #98034).
sub path   { warn 'path() is not implemented in MojoX::Log::Log4perl. Please use appenders.'   }
sub handle { warn 'handle() is not implemented in MojoX::Log::Log4perl. Please use appenders.' }
sub format {
    if (!$format_warning_was_shown) {
        $format_warning_was_shown = 1;
        warn 'format() is not properly implemented in MojoX::Log::Log4perl. Please use appenders.';
    }
    return sub { '[' . localtime(shift) . '] [' . shift() . '] ' . join("\n", @_, '') };
}

sub new {
	my ($class, $conf_file, $watch) = (@_);

	$conf_file ||= {
		'log4perl.rootLogger' => 'DEBUG, SCREEN',
		'log4perl.appender.SCREEN' => 'Log::Log4perl::Appender::Screen',
		'log4perl.appender.SCREEN.layout' => 'PatternLayout',
		'log4perl.appender.SCREEN.layout.ConversionPattern' => '[%d] [mojo] [%p] %m%n',
	};

	if ($watch) {
		Log::Log4perl::init_and_watch($conf_file, $watch);
	}
	else {
		Log::Log4perl->init_once($conf_file);
	}

	my $self = $class->SUPER::new();
	$self->on( message => \&_message );
	return $self;
}

# Hmm. Ah, a picture of my mommy.
{
    no strict 'refs';
    for my $level (
      qw/ trace
          debug
          info
          warn
          error
          fatal
          logwarn
          logdie
          error_warn
          error_die
          logcarp
          logcluck
          logcroak
          logconfess
        / ) {

        *{ __PACKAGE__ . "::$level" } =
            sub {
                return shift->emit( message => $level => @_ );
            };
    }
}

sub _message {
	my ($self, $level, @message ) = @_;
	my $depth = 3;
	local $Log::Log4perl::caller_depth
      = $Log::Log4perl::caller_depth + $depth;

	if ($self->_get_logger( $depth )->$level( @message )) {
		my $history = $self->history;
		my $max     = $self->max_history_size;
		push @$history => [ time, $level, @message ];
		splice (@$history, 0, scalar @$history - $max)
		    if scalar @$history > $max;
	}
	return $self;
}

sub log { shift->emit('message', lc(shift), @_) }

sub is_trace { shift->_get_logger->is_trace }
sub is_debug { shift->_get_logger->is_debug }
sub is_info  { shift->_get_logger->is_info  }
sub is_warn  { shift->_get_logger->is_warn  }
sub is_error { shift->_get_logger->is_error }
sub is_fatal { shift->_get_logger->is_fatal }

sub is_level {
	my ($self, $level) = (@_);
	return 0 unless $level;

	if ($level =~ m/^(?:trace|debug|info|warn|error|fatal)$/o) {
		my $is_level = "is_$level";
		return $self->_get_logger->$is_level;
	}
	else {
		return 0;
	}
}

sub level {
	my ($self, $level) = (@_);
	my $logger = $self->_get_logger;

	require Log::Log4perl::Level;
	if ($level) {
		return $logger->level( Log::Log4perl::Level::to_priority(uc $level) );
	}
	else {
		return Log::Log4perl::Level::to_level( $logger->level() );
	}
}

# $_[0] == $self, $_[1] == optional caller level (defaults to 1)
sub _get_logger {
	return Log::Log4perl->get_logger( scalar caller( $_[1] || 1 ) );
}

1;
__END__
=head1 NAME

MojoX::Log::Log4perl - Log::Log4perl logging for Mojo/Mojolicious


=head1 SYNOPSIS

In lib/MyApp.pm:

  use MojoX::Log::Log4perl;

  # just create a custom logger object for Mojo/Mojolicious to use
  # (this is usually done inside the "startup" sub on Mojolicious).
  # If we dont supply any arguments to new, it will work almost
  # like the default Mojo logger.
  
  $self->log( MojoX::Log::Log4perl->new() );

  # But the real power of Log4perl lies in the configuration, so
  # lets try that. example.conf is included in the distribution.
  
  $self->log( MojoX::Log::Log4perl->new('example.conf') );

  # you can even make it periodically check for changes in the
  # configuration file and automatically reload them while your
  # app is still running!

  # check for changes every 10 seconds
  $self->log( MojoX::Log::Log4perl->new('example.conf', 10)    );

  # or check for changes only upon receiving SIGHUP
  $self->log( MojoX::Log::Log4perl->new('example.conf', 'HUP') );


And later, inside any Mojo/Mojolicious module...

  $c->app->log->debug("This is using log4perl!");


=head1 DESCRIPTION:

This module provides a Mojo::Log implementation that uses Log::Log4perl as the underlying log mechanism. It provides all the methods listed in Mojo::Log (and many more from Log4perl - see below), so, if you already use Mojo::Log in your application, there is no need to change a single line of code!

There will be a logger component set for the package that called it. For example, if you were in the MyApp::Main package, the following:

  package MyApp::Main;
  use base 'Mojolicious::Controller';
	
  sub default {
      my ( $self, $c ) = @_;
      my $logger = $c->app->log;
      
      $logger->debug("Woot!");
  }

Would send a message to the C<< Myapp.Main >> Log4perl component. This allows you to seamlessly use Log4perl with Mojo/Mojolicious applications, being able to setup everything from the configuration file. For example, in this case, we could have the following C<< log4perl.conf >> file:

  # setup default log level and appender
  log4perl.rootLogger = DEBUG, FOO
  log4perl.appender.FOO = Log::Log4perl::Appender::File
  log4perl.appender.FOO.layout

  # setup so MyApp::Main only logs fatal errors
  log4perl.logger.MyApp.Main = FATAL

See L<< Log::Log4perl >> and L<< Log::Log4perl::Config >> for more information on how to configure different logging mechanisms based on the component.


=head1 INSTANTIATION

=head2 new

=head2 new($config)

This builds a new MojoX::Log::Log4perl object. If you provide an argument to new(), it will be passed directly to Log::Log4perl::init.
    
What you usually do is pass a file name with your Log4perl configuration. But you can also pass a hash reference with keys and values set as Log4perl configuration elements (i.e. left side of '=' vs. right side).

If you don't give it any arguments, the following default configuration is set:

  log4perl.rootLogger = DEBUG, SCREEN
  log4perl.appender.SCREEN = Log::Log4perl::Appender::Screen
  log4perl.appender.SCREEN.layout = PatternLayout
  log4perl.appender.SCREEN.layout.ConversionPattern = [%d] [mojo] [%p] %m%n

=head2 new( $config, $delay )

As an optional second argument to C<new()>, you can set a delay in seconds that will be passed directly to Log::Log4perl::init_and_watch. This makes Log4perl check every C<$delay> seconds for changes in the configuration file, and reload it if the file modification time is different.

You can also define a signal to watch and Log4perl will setup a signal handler to check the configuration file again only when that particular signal is received by the application, for example via the C<kill> command:

  kill -HUP pid


=head1 LOG LEVELS

  $logger->warn("something's wrong");

Below are all log levels from MojoX::Log::Log4perl, in descending priority:

=head2 C<fatal>

=head2 C<error>

=head2 C<warn>

=head2 C<info>

=head2 C<debug>

=head2 C<trace>

Just like C<< Log::Log4perl >>: "If your configured logging level is WARN, then messages logged with info(), debug(), and trace() will be suppressed. fatal(), error() and warn() will make their way through, because their priority is higher or equal than the configured setting."

The return value is the log object itself, to allow method chaining and further manipulation.

=head2 C<log>

You can also use the C<< log() >> method just like in C<< Mojo::Log >>:

  $logger->log( info => 'I can haz cheezburger');

But nobody does that, really.

As with the regular logging methods, the return value is the log object itself.

=head1 CHECKING LOG LEVELS

  if ($logger->is_debug) {
      # expensive debug here
  }

As usual, you can (and should) avoid doing expensive log calls by checking the current log level:

=head2 C<is_fatal>

=head2 C<is_error>

=head2 C<is_warn>

=head2 C<is_info>

=head2 C<is_debug>

=head2 C<is_trace>

=head2 C<is_level>

You can also use the C<< is_level() >> method just like in C<< Mojo::Log >>:

  $logger->is_level( 'warn' );

But nobody does that, really.

=head1 ADDITIONAL LOGGING METHODS

The following log4perl methods are also available for direct usage:

=head2 C<logwarn>

   $logger->logwarn($message);
   
This will behave just like:

   $logger->warn($message)
       && warn $message;

=head2 C<logdie>

   $logger->logdie($message);
   
This will behave just like:

   $logger->fatal($message)
       && die $message;

If you also wish to use the ERROR log level with C<< warn() >> and C<< die() >>, you can:

=head2 C<error_warn>

   $logger->error_warn($message);
   
This will behave just like:

   $logger->error($message)
       && warn $message;

=head2 C<error_die>

   $logger->error_die($message);
   
This will behave just like:

   $logger->error($message)
       && die $message;


Finally, there's the Carp functions that do just what the Carp functions do, but with logging:

=head2 C<logcarp>

    $logger->logcarp();        # warn w/ 1-level stack trace

=head2 C<logcluck>

    $logger->logcluck();       # warn w/ full stack trace

=head2 C<logcroak>

    $logger->logcroak();       # die w/ 1-level stack trace

=head2 C<logconfess>

    $logger->logconfess();     # die w/ full stack trace

=head1 ATTRIBUTES

=head2 Differences from Mojo::Log

The original C<handle> and C<path> attributes from C<< Mojo::Log >> are not implemented as they make little sense in a Log4perl environment, and will trigger a warning if you try to use them.

The C<format> attribute is also not implemented, and will trigger a warning when used. For compatibility with Mojolicious' current I<404> development page, this attribute will work returning a basic formatted message as I<"[ date ] [ level ] message">. We do B<not> recommend you to rely on this as we may remove it in the future. Please use Log4perl's layout formatters instead.

The following attributes are still available:

=head2 C<level>

  my $level = $logger->level();
  
This will return an UPPERCASED string with the current log level (C<'DEBUG'>, C<'INFO'>, ...).

Note: You can also use this to force a level of your choosing:

  $logger->level('warn');  # forces 'warn' level (case-insensitive)

But you really shouldn't do that at all, as it breaks log4perl's configuration structure. The whole point of Log4perl is letting you setup your logging from outside your code. So, once again: B<don't do this>.

=head2 C<history>

This returns the last few logged messages as an array reference in the format:

    [
        [ 'timestamp', 'level', 'message' ], # older first
        [ 'timestamp', 'level', 'message' ],
        ...
    ]

=head2 C<max_history_size>

Maximum number of messages to be kept in the history buffer (see above). Defaults to 10.

=head1 AUTHOR

Breno G. de Oliveira, C<< <garu at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mojo-log-log4perl at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MojoX-Log-Log4perl>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MojoX::Log::Log4perl


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MojoX-Log-Log4perl>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MojoX-Log-Log4perl>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MojoX-Log-Log4perl>

=item * Search CPAN

L<http://search.cpan.org/dist/MojoX-Log-Log4perl/>

=back


=head1 ACKNOWLEDGEMENTS

This module was heavily inspired by L<< Catalyst::Log::Log4perl >>. A lot of the documentation and specifications were taken almost verbatim from it.

Also, this is just a minor work. Credit is really due to Michael Schilli and Sebastian Riedel, creators and maintainers of L<< Log::Log4perl >> and L<< Mojo >>, respectively.


=head1 SEE ALSO

L<< Log::Log4perl >>, L<< Mojo::Log >>, L<< Mojo >>, L<< Mojolicious >>


=head1 COPYRIGHT & LICENSE

Copyright 2009-2016 Breno G. de Oliveira, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
