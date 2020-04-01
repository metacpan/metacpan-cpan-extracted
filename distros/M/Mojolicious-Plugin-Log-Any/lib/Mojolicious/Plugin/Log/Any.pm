package Mojolicious::Plugin::Log::Any;

use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = 'v1.0.1';

sub register {
  my ($self, $app, $conf) = @_;
  
  my $logger = delete $conf->{logger} // 'Log::Any';
  my %opt = %$conf;
  $opt{category} //= ref $app;
  
  $app->log->with_roles('Mojo::Log::Role::AttachLogger')->level('debug')
    ->unsubscribe('message')->attach_logger($logger, \%opt);
}

1;

=head1 NAME

Mojolicious::Plugin::Log::Any - Use other loggers in a Mojolicious application

=head1 SYNOPSIS

  package MyApp;
  use Mojo::Base 'Mojolicious';
  
  sub startup {
    my $self = shift;
    
    # Log::Any (default)
    use Log::Any::Adapter {category => 'MyApp'}, 'Syslog';
    $self->plugin('Log::Any');
    
    # Log::Contextual
    use Log::Contextual::WarnLogger;
    use Log::Contextual -logger => Log::Contextual::WarnLogger->new({env_prefix => 'MYAPP'});
    $self->plugin('Log::Any' => {logger => 'Log::Contextual});
    
    # Log::Dispatch
    use Log::Dispatch;
    my $logger = Log::Dispatch->new(outputs => ['File::Locked',
      min_level => 'warning',
      filename  => '/path/to/file.log',
      mode      => 'append',
      newline   => 1,
      callbacks => sub { my %p = @_; '[' . localtime() . '] ' . $p{message} },
    ]);
    $self->plugin('Log::Any' => {logger => $logger});
    
    # Log::Dispatchouli
    use Log::Dispatchouli;
    my $logger = Log::Dispatchouli->new({ident => 'MyApp', facility => 'daemon', to_file => 1});
    $self->plugin('Log::Any' => {logger => $logger});
    
    # Log::Log4perl
    use Log::Log4perl;
    Log::Log4perl->init($self->home->child('log.conf')->to_string);
    $self->plugin('Log::Any' => {logger => 'Log::Log4perl'});
  }
  
  # or in a Mojolicious::Lite app
  use Mojolicious::Lite;
  use Log::Any::Adapter {category => 'Mojolicious::Lite'}, File => app->home->child('myapp.log'), log_level => 'info';
  plugin 'Log::Any';

=head1 DESCRIPTION

L<Mojolicious::Plugin::Log::Any> is a L<Mojolicious> plugin that redirects the
application logger to pass its log messages to an external logging framework
using L<Mojo::Log::Role::AttachLogger/"attach_logger">. By default, L<Log::Any>
is used, but a different framework or object may be specified. For L<Log::Any>
or L<Log::Log4perl>, log messages are dispatched with a category of the
application class name, which is C<Mojolicious::Lite> for lite applications.

The default behavior of the L<Mojo::Log> object to filter messages by level,
keep history, prepend a timestamp, and write log messages to a file or STDERR
will be suppressed, by setting the application log level to C<debug> (the
lowest level) and removing the default L<Mojo::Log/"message"> handler. It is
expected that the logging framework output handler will be configured to handle
these details as necessary. If you want to customize how the logging framework
is attached, use L<Mojo::Log::Role::AttachLogger> directly.

=head1 METHODS

L<Mojolicious::Plugin::Log::Any> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);
  $plugin->register(Mojolicious->new, {logger => $logger});

Register logger in L<Mojolicious> application. Takes the following options:

=over

=item logger

Logging framework or object to pass log messages to, of a type recognized by
L<Mojo::Log::Role::AttachLogger/"attach_logger">. Defaults to C<Log::Any>.

=item category

Passed through to L<Mojo::Log::Role::AttachLogger/"attach_logger">. Defaults to
the application name.

=item prepend_level

Passed through to L<Mojo::Log::Role::AttachLogger/"attach_logger">.

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

L<Mojo::Log>, L<Mojo::Log::Role::AttachLogger>
