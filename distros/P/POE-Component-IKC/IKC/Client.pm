package POE::Component::IKC::Client;

############################################################
# $Id: Client.pm 1247 2014-07-07 09:06:34Z fil $
# Based on refserver.perl
# Contributed by Artur Bergman <artur@vogon-solutions.com>
# Revised for 0.06 by Rocco Caputo <troc@netrus.net>
# Turned into a module by Philp Gwyn <fil@pied.nu>
#
# Copyright 1999-2014 Philip Gwyn.  All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# Contributed portions of IKC may be copyright by their respective
# contributors.  

use strict;
use Socket;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use POE qw(Wheel::ListenAccept Wheel::SocketFactory);
use POE::Component::IKC::Responder;
use POE::Component::IKC::Channel;
use POE::Component::IKC::Util;
use Carp;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(create_ikc_client);
$VERSION = '0.2402';

sub DEBUG { 0 }


###############################################################################
#----------------------------------------------------
# This is just a convenient way to create servers.  To be useful in
# multi-server situations, it probably should accept a bind address
# and port.
sub create_ikc_client
{
    my(%parms)=@_;
    $parms{package}||=__PACKAGE__;
    $parms{package}->spawn( %parms );
}

sub spawn
{
    POE::Component::IKC::Responder->spawn;


    T->start( 'IKC' );
    my( $package, %parms ) = @_;
    $parms{package} ||= $package;

    $parms{on_connect}||=sub{};         # would be silly for this to be blank
                                        # 2001/04 not any more
    if($parms{unix}) {
    } else {
        $parms{ip}||='localhost';           
        $parms{port}||=903;                 # POE! (almost :)
    }
    $parms{name}||="Client$$";
    $parms{subscribe}||=[];
    $parms{protocol}||='IKC0';
    my $defaults;
    if($parms{serializers}) {               # use ones provided
                                            # make sure it's an arrayref
        $parms{serializers}=[$parms{serializers}] 
                                    unless ref $parms{serializers};
    } 
    else {                                  # use default ones
        $defaults=1;                        # but don't gripe
        $parms{serializers}=[qw(Storable FreezeThaw
                                POE::Component::IKC::Freezer)];
    }

    # make sure the serializers are real 
    my @keep;
    foreach my $p (@{$parms{serializers}}) {
        unless(_package_exists($p)) {
            my $q=$p;
            $q=~s(::)(/)g;
            DEBUG and warn "Trying to load $p ($q)\n";
            eval {require "$q.pm"; import $p ();};
            warn $@ if not $defaults and $@;
        }
        next unless _package_exists($p);
        push @keep, $p;
        DEBUG and warn "Using $p as a serializer\n";
    }
    $parms{serializers}=\@keep;

    return POE::Session->create( 
            package_states => [ $parms{package} =>
                                [qw(_start _stop _child error shutdown connected)]],
            args => [\%parms]
        )->ID;
}

sub _package_exists
{
    my($package)=@_;
    my $symtable=$::{"main::"};
    foreach my $p (split /::/, $package) {
        return unless exists $symtable->{"$p\::"};
        $symtable=$symtable->{"$p\::"};
    }
    return 1;
}

#----------------------------------------------------
# Accept POE's standard _start event, and set up the listening socket
# factory.

sub _start {
    my($kernel, $heap, $parms) = @_[KERNEL, HEAP, ARG0];

    DEBUG and warn "Client starting.\n";
    my %wheel_p=(
        SuccessEvent   => 'connected',    # generating this event on connection
        FailureEvent   => 'error'         # generating this event on error
    );
                                        # create a socket factory
    if($parms->{unix}) {
        $wheel_p{SocketDomain}=AF_UNIX;
        $wheel_p{RemoteAddress}=$parms->{unix};
#        $heap->{remote_name}="unix:$parms->{unix}";
#        $heap->{remote_name}=~s/[^-:.\w]+/_/g;
        $heap->{unix}=$parms->{unix};
    } else {
        $wheel_p{RemotePort}=$parms->{port};
        $wheel_p{RemoteAddress}=$parms->{ip};

        $heap->{remote_name}="$parms->{ip}:$parms->{port}";
    }
    $heap->{wheel} = new POE::Wheel::SocketFactory(%wheel_p);
    $heap->{on_connect}=$parms->{on_connect};
    $heap->{on_error}=$parms->{on_error};
    $heap->{name}=$parms->{name};
    $heap->{alias} = "IKC Client $heap->{name}";
    $kernel->alias_set( $heap->{alias} );
    $heap->{subscribe}=$parms->{subscribe};
    $heap->{aliases}=$parms->{aliases};
    $heap->{serializers}=$parms->{serializers};
    $heap->{protocol}=$parms->{protocol};

    # set up local names for kernel
    my @names=($heap->{name});
    if(exists $heap->{aliases}) {
        if(ref $heap->{aliases}) {
            push @names, @{$heap->{aliases}};
        } else {
            push @names, $heap->{aliases};
        }
    }
    $kernel->post(IKC=>'register_local', \@names);
}

#----------------------------------------------------
# Log server errors, but don't stop listening for connections.  If the
# error occurs while initializing the factory's listening socket, it
# will exit anyway.

sub error 
{
    my ($heap, $kernel, $operation, $errnum, $errstr) = @_[HEAP, KERNEL, ARG0, ARG1, ARG2];
    DEBUG and warn "Client encountered $operation error $errnum: $errstr\n";
    my $w=delete $heap->{wheel};
    # WORK AROUND
    # $w->DESTROY;
    POE::Component::IKC::Util::monitor_error( $heap, $operation, $errnum, $errstr);
    if( $heap->{alias} ) {
        $kernel->alias_remove( delete $heap->{alias} );
    }
}

#----------------------------------------------------
# The socket factory invokes this state to take care of accepted
# connections.

sub connected
{
    my ($heap, $handle, $addr, $port) = @_[HEAP, ARG0, ARG1, ARG2];
    DEBUG and warn "Client connected\n"; 

    T->point( IKC => 'connected' );
                        # give the connection to a Channel
    my %p = ( handle=>$handle, addr=>$addr, port=>$port, client=>1 );
    my @list = qw(name on_connect on_error subscribe remote_name wheel aliases unix
                   serializers protocol);
    @p{@list} = @{$heap}{@list};
    $p{rname} = delete $p{remote_name};
    $heap->{channel} = POE::Component::IKC::Channel->spawn( %p );
    return;
}

sub shutdown
{
    my ($heap, $kernel) = @_[HEAP, KERNEL];
    DEBUG and 
        warn "$heap Client shutdown";
    if( $heap->{channel} ) {
        $kernel->call( delete $heap->{channel} => 'shutdown' );
    }
    if( $heap->{alias} ) {
        $kernel->alias_remove( delete $heap->{alias} );
    }
}

sub _stop
{
    DEBUG and warn "$_[HEAP] client _stop\n";
}

sub _child
{
    my( $heap, $reason, $child ) = @_[ HEAP, ARG0, ARG1 ];
    $child = $child->ID;
    DEBUG and warn "$heap $reason #$child";
    return unless defined $heap->{channel};
    if( $child eq $heap->{channel} and $reason eq 'lose' ) {
        delete $heap->{channel};
        $poe_kernel->yield( 'shutdown' );
    }
}

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

POE::Component::IKC::Client - POE Inter-Kernel Communication client

=head1 SYNOPSIS

    use POE;
    use POE::Component::IKC::Client;
    POE::Component::IKC::Client->spawn(
        ip=>$ip, 
        port=>$port,
        name=>"Client$$",
        subscribe=>[qw(poe:/*/timserver)]
    );
    ...
    $poe_kernel->run();

=head1 DESCRIPTION

This module implements an POE IKC client.  An IKC client attempts to connect
to a IKC server.  If successful, it negociates certain connection
parameters.  After this, the POE server and client are pretty much
identical.

=head1 EXPORTED FUNCTIONS

=head2 create_ikc_client

Syntatic sugar for POE::Component::IKC::Client->spawn.


=head1 CLASS METHODS

=head2 spawn

This methods initiates all the work of connecting to an IKC server.
Parameters are :

=over 4

=item C<ip>

Address to connect to.  Can be a doted-quad ('127.0.0.1') or a host name
('foo.pied.nu').  Defaults to '127.0.0.1', aka INADDR_LOOPBACK.

=item C<port>

Port to connect to.  Can be numeric (80) or a service ('http').

=item C<unix>

Path to unix-domain socket that the server is listening on.

=item C<name>

Local kernel name.  This is how we shall "advertise" ourself to foreign
kernels. It acts as a "kernel alias".  This parameter is temporary, pending
the addition of true kernel names in the POE core.  This name, and all
aliases will be registered with the responder so that you can post to them
as if they were remote.

=item C<aliases>

Arrayref of even more aliases for this kernel.  Fun Fun Fun!

=item C<on_connect>

Coderef that is called when the connection has been made to the foreign 
kernel.  Normaly, you would use this to start the sessions that post events
to foreign kernels.  

Note, also, that the coderef will be executed from within an IKC channel
session, NOT within your own session.  This means that things like
$poe_kernel->delay_set() won't do what you think they should.

It does, however, mean that you can get the session ID of the IKC channel for
this connection.

    POE::Component::IKC::Client->spawn(
        ....
            on_connect=>sub {
                $heap->{channel} = $poe_kernel->get_active_session()->ID;
            },
        ....
        );

However, IKC/monitor provides a more powerful mechanism for detecting
connections.  See L<POE::Component::IKC::Responder>.  


=item C<on_error>

Coderef that is called for all connection errors. You could use this to
restart the connection attempt.  Parameters are C<$operation, $errnum and
$errstr>, which correspond to POE::Wheel::SocketFactory's FailureEvent, 
which q.v.

However, IKC/monitor provides a more powerful mechanism for detecting
errors.  See L<POE::Component::IKC::Responder>.  

Note, also, that the coderef will be executed from within an IKC session,
NOT within your own session.  This means that things like
$poe_kernel->delay_set() won't do what you think they should.


=item C<subscribe>

Array ref of specifiers (either foreign sessions, or foreign states) that
you want to subscribe to.  on_connect will only be called when IKC has
managed to subscribe to all specifiers.  If it can't, it will die().  YOW
that sucks.  C<monitor> will save us all.

=item C<serializers>

Arrayref or scalar of the packages that you want to use for data
serialization.  First IKC tries to load each package.  Then, when connecting
to a server, it asks the server about each one until the server agrees to a
serializer that works on its side.

A serializer package requires 2 functions : freeze (or nfreeze) and thaw. 
See C<POE::Filter::Reference>.

The default is C<[qw(Storable FreezeThaw
POE::Component::IKC::Freezer)]>.  C<Storable> and C<FreezeThaw> are
modules in C on CPAN.  They are much much much faster then IKC's built-in
serializer C<POE::Component::IKC::Freezer>.  This serializer uses
C<Data::Dumper> and C<eval $code> to get the deed done.  There is an obvious
security problem here.  However, it has the advantage of being pure Perl and
all modules come with the core Perl distribution.

It should be noted that you should have the same version of C<Storable> on
both sides, because some versions aren't mutually compatible.

=item C<protocol>

Which IKC negociation protocol to use.  The original protocol (C<IKC>) was
synchronous and slow.  The new protocol (C<IKC0>) sends all information at
once.  IKC0 will degrade gracefully to IKC, if the client and server don't
match.

Default is IKC0.


=back

=head1 BUGS

=head1 AUTHOR

Philip Gwyn, <perl-ikc at pied.nu>

=head1 COPYRIGHT AND LICENSE

Copyright 1999-2014 by Philip Gwyn.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See L<http://www.perl.com/language/misc/Artistic.html>

=head1 SEE ALSO

L<POE>, L<POE::Component::IKC::Server>, L<POE::Component::IKC::Responder>.

=cut

