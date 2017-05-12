package Sprocket::Util::FDpasser;

use strict;
use warnings;

use Sprocket qw( Util::Observable );
use base qw( Sprocket::Util::Observable );

use Carp qw( croak );
use File::FDpasser;

BEGIN {
    $sprocket->register_hook( 'sprocket.fdpasser.accept' );
}

sub new {
    my $class = shift;
    croak "$class requires an even number of parameters" if @_ % 2;
    
    my %opts = &adjust_params;
    
    die "EndpointFile is mandatory for ".__PACKAGE__
        unless ( $opts{endpoint_file} );
    
    my $self = $class->SUPER::new( %opts );
   
    if ( $opts{connect} ) {
        $self->{endpoint_fh} = endp_connect( $opts{endpoint_file} )
            || die "Can't call File::FDpasser::endp_connect in ".__PACKAGE__.": $!\n";
    } else {
        $self->{endpoint_fh} = endp_create( $opts{endpoint_file} )
            || die "Can't call File::FDpasser::endp_create in ".__PACKAGE__.": $!\n";
        # XXX
        eval {
            chmod( 0770, $opts{endpoint_file} );
        };
    }
    
    $self->register_hook( 'sprocket.fdpasser.accept' );

    POE::Session->create(
        object_states => [
            $self => [qw(
                _start
                endpoint_readable
                shutdown
            )]
        ]
    );
    
    return $self;
}

sub _start {
    my ( $self, $kernel, $session ) = @_[ OBJECT, KERNEL, SESSION ];

    $self->{session_id} = $session->ID;
    
    $kernel->select_read( $self->{endpoint_fh} => 'endpoint_readable' );
        
    $sprocket->attach_hook(
        'sprocket.shutdown',
        $sprocket->callback( $session => 'shutdown' )
    );
    
    return;
}

sub endpoint_readable {
    my ( $self, $kernel, $session ) = @_[ OBJECT, KERNEL ];
    
    # XXX what is this uid for?
    my $uid = 0;
    my $sfh = serv_accept_fh( $self->{endpoint_fh}, $uid );
    unless ( $sfh ) {
        warn "$!";
        return;
    }
    
    my $fh = recv_fh( $sfh );
    return unless ( $fh );

    $self->broadcast( 'sprocket.fdpasser.accept', {
        source => $self,
        fh => $fh,
    } );
    
    $sprocket->broadcast( 'sprocket.fdpasser.accept', {
        source => $self,
        fh => $fh,
    } );
    
    return;
}

sub send_fd {
    my ( $self, $fh ) = @_;
    
    return send_file( $self->{endpoint_fh}, $fh );
}

sub shutdown {
    my $self = shift;
    
    $poe_kernel->select_read( $self->{endpoint_fh} )
        if ( $self->{endpoint_fh} );

    return;
}

1;

__END__

=pod

=head1 NAME

Sprocket::Util::FDpasser - Pass File Descripters using File::FDpasser

=head1 SYNOPSIS

    my $passer = Sprocket::Util::FDpasser->new(
        EndpointFile => '/tmp/fdpasser',
        Connect => 0
    );

    $passer->attach_hook( 'sprocket.fdpasser.accept', sub {
        my $event = shift;
        warn "received filehandle: $event->{fh}";
    } );
    
    # send a file handle
    $passer->send_fd( *STDIN{IO} );

=head1 DESCRIPTION

This module provides a session that watches File::FDpasser's filehandle for
readability, and emits an event for received file handles.

This module is a subclass of L<Sprocket::Util::Observable> and inherits all
of its methods.

=head1 METHODS

=over 4

=item new

Create a new FD passer object

=over 4

=item EndpointFile => (str)

A path to an FDpasser endpoint.

=item Connect => (true|false)

Connect to (true) or create (false) the endpoint

=back

=item send_fd( $filehandle )

=back

=head1 HOOKS

=over 4

=item sprocket.fdpasser.accept

Emitted on $self and $sprocket, in that order.  $event->{fh} is the filehandle
received.

=back

=head1 SEE ALSO

L<Sprocket>, L<Sprocket::Util::Observable>, L<File::FDpasser>

=head1 AUTHOR

David Davis E<lt>xantus@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2007 by David Davis

See L<Sprocket> for license information.

=cut

