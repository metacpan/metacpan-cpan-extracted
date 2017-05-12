use strict;
use warnings;

package POE::Component::Server::Postfix;
our $VERSION = '0.001';


# ABSTRACT: Postfix (MTA) server toolkit


use MooseX::POE;
use POE qw(
  Filter::Postfix::Base64
  Filter::Postfix::Null
  Filter::Postfix::Plain
  Wheel::SocketFactory
  Wheel::ReadWrite
);
use Socket ();

has server  => (is => 'ro', lazy_build => 1);
has clients => (is => 'ro', isa => 'HashRef', default => sub { {} });
has handler => (is => 'ro', isa => 'CodeRef', required => 1);
has filter  => (is => 'ro', isa => 'Str', required => 1);

sub _build_server {
  my ($self) = @_;
  return POE::Wheel::SocketFactory->new(
    Reuse => 1,
    SuccessEvent => 'accept',
    FailureEvent => 'server_error',
    $self->socketfactory_args,
  );
}

sub new {
  my $class = shift;
  return $class->SUPER::new(@_) unless $class eq __PACKAGE__;
  my $arg = $class->BUILDARGS(@_);
  unless ($arg->{port} xor $arg->{path}) {
    Carp::croak "use exactly one of 'port' (TCP) or 'path' (UNIX) arguments";
  }
  if ($arg->{port}) {
    eval "require $class\::TCP; 1" or die $@;
    return "$class\::TCP"->new($arg);
  } else {
    eval "require $class\::UNIX; 1" or die $@;
    return "$class\::UNIX"->new($arg);
  }
}

sub START {
  my ($self) = @_;
  $self->server;
}

sub _filter {
  my ($self) = @_;
  my $class = my $filter = $self->filter;
  $class = "POE::Filter::Postfix::$class"
    unless $class =~ s/^=//;
  eval "require $class; 1" or die "Invalid filter '$filter': $@";
  return $class->new;
}

event accept => sub {
  my ($self, $sock) = @_[OBJECT, ARG0];
  my $wheel = POE::Wheel::ReadWrite->new(
    Handle => $sock,
    Filter => $self->_filter,
    InputEvent => 'handle_request',
    ErrorEvent => 'client_error',
  );
  $self->clients->{$wheel->ID} = $wheel;
};

event server_error => sub {
  die "server error: @_";
};

event handle_request => sub {
  my ($self, $attr, $id) = @_[OBJECT, ARG0..ARG1];
  $self->clients->{$id}->put(
    $self->handler->($self, $attr)
  );
};

event client_error => sub {
  my ($self, $id) = @_[OBJECT, ARG3];
  warn "client $id got error\n";
  delete $self->clients->{$id};
};

1;

__END__
=head1 NAME

POE::Component::Server::Postfix - Postfix (MTA) server toolkit

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  my $server = POE::Component::Server::Postfix->new(
    path => '/tmp/server', # unix socket OR

    port => 9999,          # tcp socket (not both)
    host => '127.0.0.1',   # default is 0.0.0.0

    filter => 'Plain',     # POE::Filter::Postfix::*

    handler => sub {
      my ($server, $attr) = @_;
      return { action => 'DUNNO' };
    },
  );
  POE::Kernel->run;

=head1 AUTHOR

  Hans Dieter Pearcey <hdp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Hans Dieter Pearcey.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

