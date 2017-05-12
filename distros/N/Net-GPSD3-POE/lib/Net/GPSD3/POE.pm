package Net::GPSD3::POE;
use strict;
use warnings;
use base qw{Net::GPSD3};
use POE::Session;
use POE::Wheel::ReadWrite;
use POE::Filter::Line;
use POE::Kernel; #exports $poe_kernel

our $VERSION='0.17';

=head1 NAME

Net::GPSD3::POE - Net::GPSD3 POE Session object

=head1 SYNOPSIS

  use POE;
  use Net::GPSD3::POE;
  my $gpsd=Net::GPSD3::POE->new;
  #$gpsd->addHandler;
  $gpsd->session;
  #other POE::Sessions...
  POE::Kernel->run;

One Liner

  perl -MPOE -MNet::GPSD3::POE -e 'Net::GPSD3::POE->new->session;POE::Kernel->run;'

=head1 DESCRIPTION

This package adds a L<POE::Session> capabilty to Net::GPSD3.

=head1 METHODS

=head2 session

Configures and returns the POE::Session ID

=cut

sub session {
  my $self=shift; #ISA Net::GPSD::POE
  $self->{"session"}=POE::Session->create(
    object_states => [
      $self         => {
        _start      => '_session_start',
        _stop       => '_session_stop',
        shutdown    => '_session_shutdown',
        input_event => '_event_handler',
        pause       => 'pause',
        resume      => 'resume',
      }])->ID unless $self->{"session"};
  return $self->{"session"};
}

sub _session_start {
  my $self=shift;
  $self->{"wheel"}=POE::Wheel::ReadWrite->new(
    InputEvent => "input_event",
    Handle     => $self->socket,
    Filter     => POE::Filter::Line->new(
      InputLiteral  => "\r\n",
      OutputLiteral => "\n",
    ),
  );
  $self->resume;
  return $self;
}

=head2 resume

Resumes or starts the watcher stream but not the socket

=cut

sub resume {
  my $self=shift;
  if ($self->{"wheel"}) {
    $self->{"wheel"}->put($self->_watch_string_on);
    delete $self->{"paused"} if exists $self->{"paused"};
  }
  return $self;
}

=head2 pause

Pauses or turns off the watcher stream but not the socket

=cut

sub pause {
  my $self=shift;
  unless ($self->{"paused"}) {
    $self->{"wheel"}->put($self->_watch_string_off)
      if $self->{"wheel"};
    $self->{"paused"}=1; #Should we get this from the WATCH return?
  }
  return $self;
}

sub _session_stop {
  my $self=shift;
  $poe_kernel->call($self->{"session"}, "shutdown")
    if $self->{"session"};
  return $self;
}

sub _session_shutdown {
  my $self=$_[OBJECT];
  return delete $self->{"wheel"};
}

sub _event_handler {
  my ($self, $line)=@_[OBJECT, ARG0];
  my @handler=$self->handlers;
  push @handler, \&Net::GPSD3::default_handler unless scalar(@handler);
  my $object=$self->constructor($self->decode($line), string=>$line);
  $_->($object) foreach @handler;
  $self->cache($object);
  return $self;
}

=head1 BUGS

Log on RT and Send to gpsd-dev email list

=head1 SUPPORT

DavisNetworks.com supports all Perl applications including this package.

Try gpsd-dev email list

=head1 AUTHOR

  Michael R. Davis
  CPAN ID: MRDVT
  STOP, LLC
  domain=>michaelrdavis,tld=>com,account=>perl
  http://www.stopllc.com/

=head1 COPYRIGHT

This program is free software licensed under the...

  The BSD License

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

L<Net::GPSD3>, L<POE>, L<POE::Session>, L<POE::Wheel::ReadWrite>, L<POE::Filter::Line>

=cut

1;
