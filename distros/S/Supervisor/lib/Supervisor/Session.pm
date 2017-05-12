package Supervisor::Session;

our $VERSION = '0.02';

use 5.008;
use POE;

use Supervisor::Class
  version   => $VERSION,
  base      => 'Supervisor::Base',
  utils     => 'weaken',
  constants => ':all',
  accessors => 'session log debugx',
  mutators  => 'status'
;

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

sub startup {
    my ($kernel, $self) = @_[KERNEL,OBJECT];

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my ($self, $config) = @_;

    $self->{config} = $config;

    $self->{session} = POE::Session->create(
        object_states => [
            $self => {
                _start   => '_session_start',
                _stop    => '_session_stop',
                shutdown => '_session_shutdown',
            },
            $self => [qw( _session_init startup )]
        ]
    );

    weaken($self->{session});

    $self->status(STOP);

    $self->{debugx} = $self->config('Debug') || FALSE;
    $self->{log} = Supervisor::Log->new(
        info     => 1,
        warn     => 1,
        error    => 1,
        fatal    => 1,
        debug    => $self->debugx,
        system   => $self->config('Name'),
        filename => $self->config('Logfile'),
    );

    return $self;

}

sub _initialize {
    my ($self, $kernel, $session) = @_;

}

sub _cleanup {
    my ($self, $kernel, $session) = @_;

}

# ----------------------------------------------------------------------
# Private Events
# ----------------------------------------------------------------------

sub _session_start {
    my ($kernel, $self, $session) = @_[KERNEL,OBJECT,SESSION];

    my $rc;
    my $ex = 'supervisor._session_start';
    my $alias = $self->config('Name');

    if (($rc = $kernel->alias_set($alias)) > 0) {

        $ex .= '.noalias';
        $self->throw_msg($ex, 'noalias', $alias);

    }

    $kernel->post($session, '_session_init');

}

sub _session_stop {
    my ($kernel, $self, $session) = @_[KERNEL,OBJECT,SESSION];

    $self->_cleanup($kernel, $session);

}

sub _session_shutdown {
    my ($kernel, $self, $session) = @_[KERNEL,OBJECT,SESSION];

    $self->_cleanup($kernel, $session);

}

sub _session_init {
    my ($kernel, $self, $session) = @_[KERNEL,OBJECT,SESSION];

    $self->_initialize($kernel, $session);
    $kernel->post($session, 'startup');

}

1;

__END__

=head1 NAME

Supervisor::Session - Base class for all POE Sessions.

=head1 SYNOPSIS

 my $session = Supervisor::Session->new(
     Name    => 'name',
     Logfile => 'filename.log'
 );

=head1 DESCRIPTION

This module provides an object based POE session. This object will already
have these events/methods defined.

=over 4

=item _session_start

This event will run for the initial POE "_start" event. It will
define a alias for the session. The session's alias will use the Name 
parameter. The logging subsystem will be initialized and use the Logfile 
parameter as the basis for the logfile's name. When done it will trigger
the "_session_init" event.

=item _session_init

This event will call the objects _initialize() method. When this method
returns it will trigger the "startup" event.

=item _session_stop

This event will be called during the POE "_stop" event. All it does is call
the _cleanup() method.

=item _session_shutown

This event will called during the POE "shutdown" event. All it does is call
the _cleanup() method.

=back

The following events need to be defined by your object to do something
useful.

=over 4

=item startup

This event should start whatever processing the session will do.

=back

=head1 METHODS

=over 4

=item _initialize

This is where the object should then do whatever initialization it needs 
to do. This initialization may include defining additional events. 

=item _cleanup

This method should perform cleanup actions for the session.

=back

=head1 SEE ALSO

 Supervisor
 Supervisor::Base
 Supervisor::Class
 Supervisor::Constants
 Supervisor::Controller
 Supervisor::Log
 Supervisor::Process
 Supervisor::ProcessFactory
 Supervisor::Session
 Supervisor::Utils
 Supervisor::RPC::Server
 Supervisor::RPC::Client

=head1 AUTHOR

Kevin L. Esteb, E<lt>kesteb@wsipc.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
