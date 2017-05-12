use strict;
use warnings;

package Solaris::SMF;
$Solaris::SMF::VERSION = '1.0.1';
# ABSTRACT: Manipulate Solaris 10 services from Perl

require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw( get_services );
use Params::Validate qw ( validate :types );
use Solaris::SMF::Service;
use Log::Any qw($log);
use Carp;


sub get_services {
    $log->is_trace && $log->trace( 'get_services ' . join( ',', @_ ) );
    my %p =
        validate( @_, { wildcard => { type => SCALAR, default => '*' } } );
    local $ENV{PATH} = '/bin:/usr/bin:/sbin:/usr/sbin';
    my @service_list;
    open my $svc_list, '-|', " svcs -aH '$p{wildcard}' 2>/dev/null"
        or die 'Unable to query SMF services';
    while ( my $svc_line = <$svc_list> ) {
        $log->is_trace && $log->trace($svc_line);
        my ( $state, $date, $FMRI ) = (
            $svc_line =~ m/
                ^
                ([^\s]+)        # Current state
                [\s]+
                ([^\s]+)        # Date this state was set
                [\s]+
                ( (?:svc:|lrc:) [^\s]+)        # FMRI
                \n?
                $
        /xms
        );
        $log->is_trace && $log->tracef( '$state: %s $date: %s $FMRI: %s',
            $state, $date, $FMRI );
        if ($FMRI) {
            push( @service_list, Solaris::SMF::Service->new($FMRI) );
        }
    }
    close $svc_list;
    return @service_list;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Solaris::SMF - Manipulate Solaris 10 services from Perl

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

=head1 EXPORT

=head1 FUNCTIONS

=head2 get_services

Get a list of SMF services, using an optional wildcard as a filter. The default is to return all services.

Returns a list of L<Solaris::SMF::Service> objects.

=head1 AUTHOR

Brad Macpherson <brad@teched-creations.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by TecHed Creations Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
