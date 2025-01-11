package OIDC::Client::Role::LoggerWrapper;
use utf8;
use Moose::Role;
use Moose::Util::TypeConstraints;
use namespace::autoclean;
use feature 'signatures';
no warnings 'experimental::signatures';
use Carp qw(croak);
use List::Util qw(all);

=encoding utf8

=head1 NAME

OIDC::Client::Role::LoggerWrapper - Logger wrapper

=head1 DESCRIPTION

This Moose role is used to manage different loggers, mainly because some
only accept the C<warn> method, while others only the C<warning> method.

=cut

subtype 'LoggerObject',
  as 'Object',
  where {
    my $obj = $_;
    (all { $obj->can($_) } qw/debug info error/)
      && ($obj->can('warning') || $obj->can('warn'));
  },
  message { "The 'logger' attribute you provided is not a logger object" };

has 'log' => (
  is       => 'ro',
  isa      => 'LoggerObject',
  required => 1,
);

=head1 METHODS

=head2 log_msg( $level, $message )

  $self->log_msg(info => "my log message");

Log the message.

$level only accepts C<debug>, C<info>, C<warning>, C<warn> or C<error> level.

=cut

sub log_msg ($self, $level, $message) {

  my $method = $level =~ /^(debug|info|error)$/ ? $level
             : $level =~ /^warn(ing)?$/         ? $self->log->can('warning') ? 'warning' : 'warn'
                                                : undef
    or croak("log_msg() only accepts debug, info, warning, warn or error level, not '$level'");

  $self->log->$method($message);
}

1;
