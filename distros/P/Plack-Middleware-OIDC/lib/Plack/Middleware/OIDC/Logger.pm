package Plack::Middleware::OIDC::Logger;
use 5.020;
use utf8;
use strict;
use warnings;

use feature 'signatures';
no warnings 'experimental::signatures';

=encoding utf8

=head1 NAME

Plack::Middleware::OIDC::Logger - Minimal default logger for Plack::Middleware::OIDC

=head1 DESCRIPTION

L<OIDC::Client> and L<OIDC::Client::Plugin> require a logger object that
implements the C<debug>, C<info>, C<error> and (C<warning> or C<warn>)
methods (see L<OIDC::Client::Role::LoggerWrapper>).

Unlike Mojolicious, Catalyst or Dancer2, Plack does not provide a logger
out of the box, so this small class is used by default, writing to
C<STDERR> (or to C<$env->{'psgix.logger'}> if available). You can
provide your own logger object instead via the C<log> option of
L<Plack::Middleware::OIDC>, as long as it implements the same interface.

=head1 METHODS

=head2 new( %args )

Optional C<env> argument: if given and C<$env->{'psgix.logger'}> is
set, messages are sent there instead of C<STDERR>.

=cut

sub new ($class, %args) {
  return bless { env => $args{env} }, $class;
}


=head2 set_env($env)

Sets the PSGI environment attribute.

The environment is used to access the C<psgix.logger> callback, when
available, so that log messages can be forwarded to the logging
mechanism provided by the PSGI application server.

=cut

sub set_env ($self, $env) {
  $self->{env} = $env;
  return $self;
}


sub _log ($self, $level, $message) {

  my $env = $self->{env};
  if ($env && $env->{'psgix.logger'}) {
    $env->{'psgix.logger'}->({ level => $level, message => $message });
    return;
  }

  print STDERR "[$level] $message\n";
  return;
}


=head2 debug($message)

Logs a message at the C<debug> level.

=head2 info($message)

Logs a message at the C<info> level.

=head2 warning($message)

Logs a message at the C<warn> level.

=head2 warn($message)

Logs a message at the C<warn> level.

=head2 error($message)

Logs a message at the C<error> level.

=cut

sub debug   ($self, $message) { $self->_log('debug', $message); return; }
sub info    ($self, $message) { $self->_log('info',  $message); return; }
sub warning ($self, $message) { $self->_log('warn',  $message); return; }
sub warn    ($self, $message) { $self->_log('warn',  $message); return; }
sub error   ($self, $message) { $self->_log('error', $message); return; }

1;
