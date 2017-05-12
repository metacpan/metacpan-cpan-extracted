package POE::Component::IKC::LocalKernel;

############################################################
# $Id: LocalKernel.pm 1224 2014-05-15 18:49:21Z fil $
# Copyright 1999-2014 Philip Gwyn.  All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# Contributed portions of IKC may be copyright by their respective
# contributors.  

use strict;
use POE::Session;
use POE::Component::IKC::Responder;

sub DEBUG () { 0 }

#----------------------------------------------------
sub spawn
{
    my $package=shift;
#    my %params=@_;

    POE::Component::IKC::Responder->spawn();
    POE::Session->create( 
        package_states=>[
            $package=>[qw(_start _default shutdown send sig_INT _stop)],
        ],
#        heap=>{%params},
    );
}

#----------------------------------------------------
sub _start
{
    my($kernel, $heap, $session)=@_[KERNEL, HEAP, SESSION];
    $kernel->sig(INT=>'sig_INT');
    $kernel->alias_set('-- Local Kernel IKC Channel --');
    
    $heap->{ref}=1;
}

#----------------------------------------------------
#
sub _default
{
    my($event)=$_[STATE];
    DEBUG && warn "Unknown event $event posted to IKC::LocalKernel\n"
        if $event !~ /^_/;
    return;
}

#----------------------------------------------------
sub _stop
{
#    my($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
    DEBUG && 
        warn "$$: Local kernel _stop\n";
}

#----------------------------------------------------
sub shutdown 
{
    my($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
    DEBUG && 
        warn "$$: Local kernel channel will shutdown.\n";
    return unless $heap->{ref};
    delete $heap->{ref};
    $kernel->alias_remove('-- Local Kernel IKC Channel --');
}

#----------------------------------------------------
sub send
{
    my($kernel, $heap, $request) = @_[KERNEL, HEAP, ARG0];

    DEBUG && warn "$$: Sending data...\n";
    $request->{rsvp}->{kernel}||=$kernel->ID
            if ref($request) and $request->{rsvp};

    DEBUG && warn "$$: Recieved data...\n";
    $request->{errors_to}={ kernel=>$kernel->ID,
                            session=>'IKC',
                            state=>'remote_error',
                          };
    $request->{call}->{kernel}||=$heap->{kernel_name};
    $kernel->call('IKC', 'request', $request);
    return 1;
}

#----------------------------------------------------
sub sig_INT
{
    my($kernel, $heap) = @_[KERNEL, HEAP];
    DEBUG && warn "$$: sig_INT\n";
    $kernel->yield('shutdown');
}

1;


