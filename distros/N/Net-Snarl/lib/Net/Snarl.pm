package Net::Snarl;

use strict;
use warnings;
use 5.008;
our $VERSION = 1.10;

use Carp;
use IO::Socket;
use Readonly;

=head1 NAME

Net::Snarl - Snarl network protocol

=cut

Readonly my $SNARL_PORT           => 9887;
Readonly my $SNARL_PROTO_VERSION  => '1.1';

=head1 SYNOPSIS

  use Net::Snarl;

  # connect to localhost and register Net::Snarl application
  my $snarl = Net::Snarl->register('Net::Snarl');
  $snarl->add_class('Test'); # add Test notification class
  $snarl->notify('Test', 'Hello', 'World', 5); # show hello world for 5 seconds

=head1 DESCRIPTION

A simple interface to send Snarl notifications across the network.  Snarl must
be running on the target machine.

=cut

sub _send {
  my ($self, %param) = @_;

  my $data = 'type=SNP#?version=' . $SNARL_PROTO_VERSION . '#?' .
    join('#?', map { "$_=$param{$_}" } keys %param);

  $self->{socket}->print("$data\x0d\x0a");
  return $self->_recv;
}

sub _recv {
  my ($self) = @_;

  my $data = $self->{socket}->getline();
  chomp $data;

  my ($header, $version, $code, $desc, @rest) = split '/', $data;

  die "Unexpected response: $data" unless $header eq 'SNP';

  # hackishly disregard responses above 300
  if ($code >= 300) {
    push @{$self->{queue}}, [$code, $desc, @rest];
    return $self->_recv;
  }

  return $code, $desc, @rest;
}

=head1 INTERFACE

=head2 register($application, $host, $port)

Connects to Snarl and register an application.  Host defaults to localhost and
port defaults to C<$Net::Snarl::SNARL_PORT>.

=cut

sub register {
  my ($class, $application, $host, $port) = @_;

  croak 'Cannot call register as an instance method' if ref $class;
  croak 'Application name required' unless $application;

  my $socket = IO::Socket::INET->new(
    PeerAddr  => $host || 'localhost',
    PeerPort  => $port || $SNARL_PORT,
    Proto     => 'tcp',
  ) or die "Unable to create socket: $!";

  my $self = bless { socket => $socket, application => $application }, $class;

  my ($result, $text) = $self->_send(
    action => 'register',
    app => $application,
  );

  die "Unable to register: $text" if $result;

  return $self;
}

=head2 add_class($class, $title)

Registers a notification class with your application.  Title is the optional
friendly name for the class.

=cut

sub add_class {
  my ($self, $class, $title) = @_;

  croak 'Cannot call add_class as a class method' unless ref $self;
  croak 'Class name required' unless $class;

  my ($result, $text) = $self->_send(
    action  => 'add_class',
    app     => $self->{application},
    class   => $class,
    title   => $title || $class,
  );

  die "Unable to add class: $text" if $result;

  return 1;
}

=head2 notify($class, $title, $text, $timeout, $icon)

Displays a notification of the specified class.  Timeout defaults to 0 (sticky)
and icon defaults to nothing.

=cut

sub notify {
  my ($self, $class, $title, $text, $timeout, $icon) = @_;

  croak 'Cannot call notify as a class method' unless ref $self;
  croak 'Class name required' unless $class;
  croak 'Title required' unless $title;
  croak 'Text required' unless $text;

  my ($result, $rtext) = $self->_send(
    action  => 'notification',
    app     => $self->{application},
    class   => $class,
    title   => $title,
    text    => $text,
    timeout => $timeout || 0,
    icon    => $icon || '',
  );

  die "Unable to send notification: $rtext" if $result;

  return 1;
}

sub DESTROY {
  my ($self) = @_;

  $self->_send(
    action  => 'unregister',
    app     => $self->{application},
  );

  return;
}

=head1 BUGS

Please report and bugs or feature requests on GitHub
L<https://github.com/bentglasstube/Net-Snarl/issues>

=head1 TODO

Later versions of Snarl report interactions with the notifications back to the
socket.  Currently these are stored in a private queue.  Eventually, I will
expose an interface for triggering callbacks on these events but that will most
likely require threading so I'm a little reluctant to implement it.

=head1 AUTHOR

Alan Berndt, C<< <alan@eatabrick.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Alan Berndt.

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut

1;
