package Mojo::Log::Role::AttachLogger;

use Role::Tiny;
use Carp ();
use Import::Into ();
use Module::Runtime ();
use Scalar::Util ();

our $VERSION = 'v1.0.1';

our @CARP_NOT = 'Mojolicious::Plugin::Log::Any';

requires 'on';

sub attach_logger {
  my ($self, $logger, $opt) = @_;
  Carp::croak 'No logger passed' unless defined $logger;
  my ($category, $prepend);
  if (ref $opt) {
    ($category, $prepend) = @$opt{'category','prepend_level'};
  } else {
    $category = $opt;
  }
  $category //= 'Mojo::Log';
  $prepend //= 1;
  
  my $do_log;
  if (Scalar::Util::blessed($logger)) {
    if ($logger->isa('Log::Any::Proxy')) {
      $do_log = sub {
        my ($self, $level, @msg) = @_;
        my $msg = @msg > 1 ? join("\n", @msg) : $msg[0];
        $msg = "[$level] $msg" if $prepend;
        $logger->$level($msg);
      };
    } elsif ($logger->isa('Log::Dispatch')) {
      $do_log = sub {
        my ($self, $level, @msg) = @_;
        my $msg = @msg > 1 ? join("\n", @msg) : $msg[0];
        $msg = "[$level] $msg" if $prepend;
        $level = 'critical' if $level eq 'fatal';
        $logger->log(level => $level, message => $msg);
      };
    } elsif ($logger->isa('Log::Dispatchouli') or $logger->isa('Log::Dispatchouli::Proxy')) {
      $do_log = sub {
        my ($self, $level, @msg) = @_;
        my $msg = @msg > 1 ? join("\n", @msg) : $msg[0];
        $msg = "[$level] $msg" if $prepend;
        return $logger->log_debug($msg) if $level eq 'debug';
        # hacky but we don't want to use log_fatal because it throws an
        # exception, we want to allow real exceptions to propagate, and we
        # can't localize a call to set_muted
        local $logger->{muted} = 0 if $level eq 'fatal' and $logger->get_muted;
        $logger->log($msg);
      };
    } elsif ($logger->isa('Mojo::Log')) {
      $do_log = sub {
        my ($self, $level, @msg) = @_;
        $logger->$level(@msg);
      };
    } else {
      Carp::croak "Unsupported logger object class " . ref($logger);
    }
  } elsif ($logger eq 'Log::Any') {
    require Log::Any;
    $logger = Log::Any->get_logger(category => $category);
    $do_log = sub {
      my ($self, $level, @msg) = @_;
      my $msg = @msg > 1 ? join("\n", @msg) : $msg[0];
      $msg = "[$level] $msg" if $prepend;
      $logger->$level($msg);
    };
  } elsif ($logger eq 'Log::Log4perl') {
    require Log::Log4perl;
    $logger = Log::Log4perl->get_logger($category);
    $do_log = sub {
      my ($self, $level, @msg) = @_;
      my $msg = @msg > 1 ? join("\n", @msg) : $msg[0];
      $msg = "[$level] $msg" if $prepend;
      $logger->$level($msg);
    };
  } elsif ($logger eq 'Log::Contextual' or "$logger"->isa('Log::Contextual')) {
    Module::Runtime::require_module("$logger");
    Log::Contextual->VERSION('0.008001');
    my %functions = map { ($_ => "slog_$_") } qw(debug info warn error fatal);
    "$logger"->import::into(ref($self), values %functions);
    $do_log = sub {
      my ($self, $level, @msg) = @_;
      my $msg = @msg > 1 ? join("\n", @msg) : $msg[0];
      $msg = "[$level] $msg" if $prepend;
      $self->can($functions{$level})->($msg);
    };
  } else {
    Carp::croak "Unsupported logger class $logger";
  }
  
  $self->on(message => $do_log);
  
  return $self;
}

1;

=head1 NAME

Mojo::Log::Role::AttachLogger - Use other loggers for Mojo::Log

=head1 SYNOPSIS

  use Mojo::Log;
  my $log = Mojo::Log->with_roles('+AttachLogger')->new->unsubscribe('message');
  
  # Log::Any
  use Log::Any::Adapter {category => 'Mojo::Log'}, 'Syslog';
  $log->attach_logger('Log::Any', 'Some::Category');
  
  # Log::Contextual
  use Log::Contextual::WarnLogger;
  use Log::Contextual -logger => Log::Contextual::WarnLogger->new({env_prefix => 'MYAPP'});
  $log->attach_logger('Log::Contextual');
  
  # Log::Dispatch
  use Log::Dispatch;
  my $logger = Log::Dispatch->new(outputs => ['File::Locked',
    min_level => 'warning',
    filename  => '/path/to/file.log',
    mode      => 'append',
    newline   => 1,
    callbacks => sub { my %p = @_; '[' . localtime() . '] ' . $p{message} },
  ]);
  $log->attach_logger($logger);
  
  # Log::Dispatchouli
  use Log::Dispatchouli;
  my $logger = Log::Dispatchouli->new({ident => 'MyApp', facility => 'daemon', to_file => 1});
  $log->attach_logger($logger);
  
  # Log::Log4perl
  use Log::Log4perl;
  Log::Log4perl->init('/path/to/log.conf');
  $log->attach_logger('Log::Log4perl', 'Some::Category');
  
=head1 DESCRIPTION

L<Mojo::Log::Role::AttachLogger> is a L<Role::Tiny> role for L<Mojo::Log> that
redirects log messages to an external logging framework. L</"attach_logger">
currently recognizes the strings C<Log::Any>, C<Log::Contextual>,
C<Log::Log4perl>, and objects of the classes C<Log::Any::Proxy>,
C<Log::Dispatch>, C<Log::Dispatchouli>, and C<Mojo::Log>.

The default L<Mojo::Log/"message"> event handler is not suppressed by
L</"attach_logger">, so if you want to suppress the default behavior, you
should unsubscribe from the message event first. Unsubscribing from the message
event will also remove any loggers attached by L</"attach_logger">.

Since L<Mojolicious> 8.06, the L<Mojo::Log/"message"> event will not be sent
for messages below the log level set in the L<Mojo::Log> object, so the
attached logger will only receive log messages exceeding the configured level.

L<Mojolicious::Plugin::Log::Any> can be used to attach a logger to the
L<Mojolicious> application logger and suppress the default message event
handler.

=head1 METHODS

L<Mojo::Log::Role::AttachLogger> composes the following methods.

=head2 attach_logger

  $log = $log->attach_logger($logger, $options);

Subscribes to L<Mojo::Log/"message"> and passes log messages to the given
logging framework or object. The second argument is optionally a category
(default C<Mojo::Log>) or hashref of options. The log level will be prepended
to the message in square brackets (except when passing to another L<Mojo::Log>
object, or L</"prepend_level"> is false).

The following loggers are recognized:

=over

=item Log::Any

The string C<Log::Any> will use a global L<Log::Any> logger with the specified
category (defaults to C<Mojo::Log>).

=item Log::Any::Proxy

A L<Log::Any::Proxy> object can be passed directly and will be used for logging
in the standard manner, using the object's existing category.

=item Log::Contextual

The string C<Log::Contextual> will use the global L<Log::Contextual> logger.
Package loggers are not supported. Note that L<Log::Contextual/"with_logger">
may be difficult to use with L<Mojolicious> logging due to the asynchronous
nature of the dispatch cycle.

=item Log::Dispatch

A L<Log::Dispatch> object can be passed to be used for logging. The C<fatal>
log level will be mapped to C<critical>.

=item Log::Dispatchouli

A L<Log::Dispatchouli> object can be passed to be used for logging. The
C<fatal> log level will log messages even if the object is C<muted>, but an
exception will not be thrown as L<Log::Dispatchouli/"log_fatal"> normally does.

=item Log::Log4perl

The string C<Log::Log4perl> will use a global L<Log::Log4perl> logger with the
specified category (defaults to C<Mojo::Log>).

=item Mojo::Log

Another L<Mojo::Log> object can be passed to be used for logging.

=back

The following options are supported:

=over

=item category

Category name (defaults to Mojo::Log).

=item prepend_level

Prepend the log level to messages in the form C<[$level]> (default for
non-L<Mojo::Log> loggers). Set false to disable.

=back

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Mojo::Log>, L<Log::Any>, L<Log::Contextual>, L<Log::Dispatch>,
L<Log::Dispatchouli>, L<Log::Log4perl>
