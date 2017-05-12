package Sprocket::Server::PreFork;

use strict;
use warnings;

use POE;
use Sprocket qw( Server AIO );
use Sprocket::Common qw( super_event );
use base qw( Sprocket::Server );

our $sprocket_aio;

sub spawn {
    my $class = shift;
   
    my $self = $class->SUPER::spawn( @_ );

    # 1 parent + 1 child
    $self->{opts}->{processes} ||= 2;

    # time to retry fork after failure
    # XXX undocumented
    $self->{opts}->{fork_fail_delay} ||= 2;
    
    $self->{is_child} = 0;
    $self->{children} = {};
    $self->{is_forked} = 1;

    return $self;
}

sub _startup {
    # call _startup in Sprocket::Server first
    my ( $self, $kernel, $session ) = ( &super_event )[ OBJECT, KERNEL, SESSION ];

    $kernel->state( _dofork => $self );
    $kernel->call( $session => '_dofork' );
}

sub _dofork {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];

    return if $self->{is_child};

    my $current_children = keys %{ $self->{children} };
    for ( ( $current_children + 2 ) .. $self->{opts}->{processes} ) {

        my $pid = fork();

        unless ( defined( $pid ) ) {
            $self->_log(v => 2, msg => "forked failed $!");
            $kernel->delay( _dofork => $self->{opts}->{fork_fail_delay} );
            return;
        }

        # we are the parent, add a child handler
        if ( $pid ) {
            $self->{children}->{ $pid } = 1;
            $kernel->sig_child( $pid => 'sig_child' );
            next;
        }

        # we are a child
        $self->_log(v => 2, msg => "forked successfully");
        $self->{is_child} = 1;
        $self->{children} = {};
        $self->{heaps} = {};
        $self->{connections} = 0;

        # restart AIO in the child
        $sprocket_aio->restart() if ( $sprocket_aio );
        return;
    }

}

sub sig_child {
    my ( $kernel, $self, $pid ) = @_[ KERNEL, OBJECT, ARG1 ];
    $self->_log(v => 4, msg => "cleanup of pid $pid");
    delete $self->{children}->{ $pid };
    $kernel->sig_handled();
}

1;

__END__

=head1 NAME

Sprocket::Server::PreFork - The PreForking Sprocket Server 

=head1 SYNOPSIS

    use Sprocket qw( Server::PreFork );
    
    Sprocket::Server::PreFork->spawn(
        Name => 'Test Server',
        ListenAddress => '127.0.0.1', # Defaults to INADDR_ANY
        ListenPort => 9979,           # Defaults to random port
        Plugins => [
            {
                plugin => MyPlugin->new(),
                priority => 0, # default
            },
        ],
        LogLevel => 4,
        MaxConnections => 10000,
        Processes => 4,
    );


=head1 DESCRIPTION

Sprocket::Server::PreFork forks processes for Sprocket::Server

=head1 NOTE

This module subclasses L<Sprocket:Server> with one additional parameter:
Processes => (Int).  It will fork 3 additional processes to total 4.

=head1 SEE ALSO

L<POE>, L<Sprocket>, L<Sprocket::Connection>, L<Sprocket::Plugin>,
L<Sprocket::Client>, L<Sprocket::Server>

=head1 AUTHOR

David Davis E<lt>xantus@cpan.orgE<gt>

=head1 RATING

Please rate this module.
L<http://cpanratings.perl.org/rate/?distribution=Sprocket>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2007 by David Davis

See L<Sprocket> for license information.

=cut

