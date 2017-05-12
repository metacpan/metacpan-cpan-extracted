package Proc::Safetynet::POEWorker;

use 5.008;
use strict;
use warnings;

our @ISA = qw();

our $VERSION = '0.01';

use Carp;
use POE::Kernel;
use POE::Session;
use Scalar::Util qw/weaken/;



=head1 METHODS

A worker component with object methods. 

=over 4

=item CLASS->spawn( %options )

spawns a POE session and posts the C<initialize> POE event to do initialization.

returns the object instance.

C<%options> keys are as follows:

    alias       => optional, string, POE session alias, defaults to stringified C<$self>

All other options keys will be saved and will be accessible via $obj->options as 
a hashref;

=cut
sub spawn {
    my $class = shift;
    my $self  = bless { }, $class;

    # validate options
    not( @_ & 1 )
        or confess 'odd number of parameters, expected hash';
    my %options = @_;

    my $alias = delete $options{alias} || "$self";
    $self->{alias} = $alias;

    $self->{'bind'} = { };
    $self->{options} = \%options;
    
    # create session
    my $session = POE::Session->create(
        inline_states       => {
            _start                  => sub {
                $_[KERNEL]->alias_set( $self->{alias} ) == 0
                    or confess 'cannot set alias '.$self->{alias};
                $_[KERNEL]->post( $_[SESSION], 'initialize' );
            },
            _stop                   => sub { 
                $self->cleanup();
            },
            #_child                  => sub { },
            #_parent                 => sub { },
            _default                => sub {
                my $event = $_[ARG0];
                confess "event [$event] is not a valid state for class [$class]";
            },
        },
        object_states       => [
            $self           => [qw/
                initialize 
                start_work
                shutdown
            /],
        ],
    );
    $self->{session} = $session;
    weaken($self->{session});
    return $self;
}


=item $obj->yield( $event_name, POE_args... )

Posts the event $event_name and POE_args to $obj's session.

croaks on error

=cut
sub yield {
    my $self = shift;
    POE::Kernel->post( $self->{session}->ID, @_ )
        or croak 'cannot yield: '.$!;
}



=item $obj->session

returns the object's session object.

Readonly accessor.

=cut
sub session {
    my $self = shift;
    return $self->{session};
}



=item $obj->options

returns the object's options (hashref);

Readonly accessor.

Options are the "remaining" data passed during C<spawn()>.

=cut
sub options {
    my $self = shift;
    return $self->{options};
}



=item $obj->alias

returns the object session's POE ALIAS.

Readonly accessor.

The alias may have been assigned during C<spawn()>.

=cut
sub alias {
    my $self = shift;
    return $self->{alias};
}




=item $obj->cleanup

gets called during the POE C<_stop> handling phase.

Note that the session object will get garbage collected right
after the call to this method. As per POE documentation,
POE event posting done here will not be honored.

=cut
sub cleanup {
    my $self = shift;
    # virtual
}


=item initialize

Called immediately after construction. Child classes generally override
this method for the following reasons:

    1. handle initialization based on $obj->options
    2. add additional states to the current session via POE::Kernel->state()

As part of recommended practice, the component should not do any work in
this state. Not until told to do so via C<start_work> public state.

=cut
sub initialize {
    # do nothing
}


=item start_work

start_work an advisory event to the component for it to start working; i.e.
to start its engines. The spawner session (i.e. the one who spawned the
component) is the one who knows best when is the correct time to 
"start working".

A persistent component may simply choose to do some initialization here
(read a file, connect to some host, etc.) and wait for work to be 
submitted via some other state.

Subclasses are required to override method.

=cut
sub start_work {
    confess "unimplemented state" . $_[STATE];
}


=item shutdown

Shuts down the component session. This is only necessary
if the component has a persistent lifetime. That is, sessions
that die naturally do not need to go through this shutdown process.

=cut
sub shutdown {
    my $self = $_[OBJECT];
    $_[KERNEL]->alias_remove( $self->alias );
}


1;

__END__

=back 

=head1 SEE ALSO

L<POE>

L<POE::Kernel>

L<POE::Session>

L<POE::Component>

=head1 AUTHOR

Dexter Tad-y, <dtady@xyber.ph>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Dexter Tad-y

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
