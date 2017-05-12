use strict;
use warnings;

package Solaris::SMF::Service;
$Solaris::SMF::Service::VERSION = '1.0.1';
# ABSTRACT: Encapsulate Solaris 10 services in Perl

use Params::Validate qw( validate validate_pos :types );
use Log::Any qw($log);
use Carp;


sub _svcs {
    my $self = shift;
    local $ENV{PATH} = '/bin:/usr/bin:/sbin:/usr/sbin';
    open my $svc_list, '-|', " svcs -aH '$self->{FMRI}' 2>/dev/null"
        or croak 'Unable to query SMF services';
    while ( my $svc_line = <$svc_list> ) {
        my ( $state, $date, $FMRI ) = (
            $svc_line =~ m/
                ^
                ([^\s]+)        # Current state
                [\s]+
                ([^\s]+)        # Date this state was set
                [\s]+
                ( (?: svc: | lrc: ) [^\s]+ ) # FMRI
                \n?
                $
        /xms
        );
        if ($FMRI) {
            close $svc_list;
            return ( $state, $date );
        }
    }
    croak "Unable to determine status of $self->{FMRI}";
}

sub _svcprop {
    $log->is_trace && $log->trace( '_svcprop ' . join( ',', @_ ) );
    my $self = shift;
    local $ENV{PATH} = '/bin:/usr/bin:/sbin:/usr/sbin';
    open my $svcprop_list, '-|', " svcprop '$self->{FMRI}' 2>/dev/null"
        or croak 'Unable to query SMF service properties';
    my %properties;
    while ( my $svcprop_line = <$svcprop_list> ) {
        my ( $name, $type, $value ) = (
            $svcprop_line =~ m/
                ^
                ([^\s]+)        # Property name
                [\s]+
                ([^\s]+)        # Type of property
                [\s]+
                ([^\s]*[^\n]*)        # Value of property
                $
        /xms
        );
        if ($name) {
            $properties{$name}{type}  = $type;
            $properties{$name}{value} = $value;
        }
        $log->is_trace && $log->tracef( '$name: %s $type: %s $value: %s',
            $name, $type, $value );
    }
    $log->is_trace && $log->tracef( '$properties: %s', \%properties );
    return \%properties;
}

sub _svcadm {
    $log->is_trace && $log->trace( '_svcadm ' . join( ',', @_ ) );
    my $self          = shift;
    my $svcadm_action = shift;
    local $ENV{PATH} = '/bin:/usr/bin:/sbin:/usr/sbin';
    open my $svc_adm, '-|', " svcadm $svcadm_action '$self->{FMRI}' 2>&1"
        or croak 'Unable to administer SMF services';
    close $svc_adm;
}


sub new {
    my $class = shift;
    my $FMRI  = shift;
    $log->is_trace && $log->trace("$class -> new( '$FMRI' )");
    my $service = bless {}, __PACKAGE__;
    $service->{FMRI} = $FMRI;
    return $service;
}


sub status {
    $log->is_trace && $log->trace( 'status ' . join( ',', @_ ) );
    my $self = shift;
    my ( $status, $date ) = $self->_svcs();
    $log->is_trace && $log->tracef( '$status: %s $date: %s', $status, $date );
    return $status;
}


sub FMRI {
    $log->is_trace && $log->trace( 'FMRI ' . join( ',', @_ ) );
    my $self = shift;
    return $self->{FMRI};
}


sub properties {
    $log->is_trace && $log->trace( 'properties ' . join( ',', @_ ) );
    my $self       = shift;
    my $properties = $self->_svcprop();
    return %{$properties};
}


sub property {
    $log->is_trace && $log->trace( 'property ' . join( ',', @_ ) );
    my $self            = shift;
    my $p               = validate_pos( @_, { type => SCALAR } );
    my ($property_name) = @{$p};

    my $properties = $self->_svcprop();
    $log->is_trace && $log->tracef( '$properties: %s', $properties );
    if ( defined $properties->{$property_name} ) {
        return $properties->{$property_name}{value};
    }
    else {
        carp "Unable to find property '$property_name' for " . $self->{FMRI};
        undef;
    }
}


sub property_type {
    $log->is_trace && $log->trace( 'property_type ' . join( ',', @_ ) );
    my $self            = shift;
    my $p               = validate_pos( @_, { type => SCALAR } );
    my ($property_name) = @{$p};

    my $properties = $self->_svcprop();
    $log->is_trace && $log->tracef( '$properties: %s', $properties );
    if ( defined $properties->{$property_name} ) {
        return $properties->{$property_name}{type};
    }
    else {
        carp "Unable to find property '$property_name' for " . $self->{FMRI};
        undef;
    }
}


sub disable {
    $log->is_trace && $log->trace( 'disable ' . join( ',', @_ ) );
    my $self = shift;
    return $self->_svcadm('disable');
}


sub stop {
    $log->is_trace && $log->trace( 'stop ' . join( ',', @_ ) );
    my $self = shift;
    return $self->_svcadm('disable -t');
}


sub enable {
    $log->is_trace && $log->trace( 'enable ' . join( ',', @_ ) );
    my $self = shift;
    return $self->_svcadm('enable');
}


sub start {
    $log->is_trace && $log->trace( 'start ' . join( ',', @_ ) );
    my $self = shift;
    return $self->_svcadm('enable -t');
}


sub refresh {
    $log->is_trace && $log->trace( 'refresh ' . join( ',', @_ ) );
    my $self = shift;
    return $self->_svcadm('refresh');
}


sub clear {
    $log->is_trace && $log->trace( 'clear ' . join( ',', @_ ) );
    my $self = shift;
    return $self->_svcadm('clear');
}


sub mark {
    $log->is_trace && $log->trace( 'mark ' . join( ',', @_ ) );
    my $self = shift;
    return $self->_svcadm('mark');
}

1;    # End of Solaris::SMF::Service

__END__

=pod

=encoding UTF-8

=head1 NAME

Solaris::SMF::Service - Encapsulate Solaris 10 services in Perl

=head1 VERSION

version 1.0.1

=head1 SYNOPSIS

Interface to Sun's Service Management Facility in Solaris 10. This module provides
a wrapper around 'svcs', 'svcadm' and 'svccfg'.

The SMF in Solaris is a replacement for inetd as well as the runlevel-based stopping
and starting of daemons. Service definitions are stored in an XML database.

The biggest advantages in using SMF are the resiliency support, consistent interface and
inter-service dependencies it offers. Services that die for any reason can be automatically
restarted by the operating system; all services can be enabled or disabled using the same
commands; and services can be started as soon as all the services they depend upon have
been started, rather than at a fixed point in the boot process.

=head1 METHODS


=head2 new

Create a new Service object. The parameter must be a valid, unique FMRI.


=head2 status

Get the current status of this service. Returns a string, 'disabled', 'enabled', 'offline'.


=head2 FMRI

Returns the Fault Managed Resource Identifier for this service.


=head2 properties

Returns all or some properties for this service.


=head2 property

Returns the value of a single property of this service.


=head2 property_type

Returns the type of a single property of this service.


=head2 disable

This instructs SMF to disable the service permanently. To disable temporarily,
that is until the next time the server is rebooted, use the 'stop' method.


=head2 stop

This instructs SMF to stop the service. It uses the -t flag to svcadm, so that
using this call will not prevent the service from starting the next time the
server reboots.


=head2 enable

This instructs SMF to enable the service permanently. To enable temporarily,
that is until the next time the server is rebooted, see the 'start' method.


=head2 start

This instructs SMF to start the service. This change is not made persistent
unless you use the 'enable' method.


=head2 refresh

This instructs SMF to refresh the service. Needed whenever alterations are
made to a service's properties. It acts as the analogue of a SQL 'commit'.


=head2 clear

This instructs SMF to clear the service's state, that is, to remove the
'failed' marker from it. This is needed prior to starting a failed service.


=head2 mark

This instructs SMF to mark the service as failed.

=head1 AUTHOR

Brad Macpherson <brad@teched-creations.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by TecHed Creations Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
