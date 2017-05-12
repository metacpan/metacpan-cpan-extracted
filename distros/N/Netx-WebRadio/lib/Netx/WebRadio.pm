
package Netx::WebRadio;
use strict;
use warnings;

use Carp;

BEGIN {
	#use Exporter ();
	use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = 0.03;
	#@ISA         = qw (Exporter);
	#@EXPORT      = qw ();
	#@EXPORT_OK   = qw ();
	#%EXPORT_TAGS = ();

    use strict;
    use IO::Poll 0.04 qw(POLLIN POLLOUT POLLERR POLLHUP);

    use Class::MethodMaker
	new_with_init       =>  'new',
	get_set                  => [ qw /timeout poll stations station_sockets/ ];

}


=head1 NAME

Netx::WebRadio - receive one or more webradio-stations

=head1 SYNOPSIS

  use Netx::WebRadio
  my $receiver = Netx::WebRadio->new();

  my $station = Netx::WebRadio::Station::Shoutcast->new();
  $station->host( $server->[0] );
  $station->port( $server->[1] );
  $receiver->add_station( $station ) if  $station->connect( $server->[0], $server->[1] ) ;
  
  while ($receiver->number_of_stations) {
     $receiver->receive();
  }

=head1 DESCRIPTION

THIS IS BETA SOFTWARE!

Netx::WebRadio is a framework for receiving one or more webradio streams.

It's implemented with the so-called 'template-pattern' - inherit from it and overload some mehtods.

Netx::WebRadio works as a multiplexer for one or more Netx::WebRadio::Station-objects (eg Netx::WebRadio::Station::Shoutcast).

=head1 USAGE

To change the handling of certain events (timeout, disconnect) you have to overload some methods.

Look at the Examples/ directory for examples.

=head1 METHODS

=head2 add_station

 Usage     : $receiver->add_station( $station )
 Purpose   :
    Adds a (already connected) station for receiving.
 Returns   : nothing
 Argument  : station-object
 Throws    : nothing
 See Also   : remove_station

=cut

sub add_station {
    my ($self, $station) = @_;
    croak "no station specified" unless $station;
    $self->poll->mask( $station->socket => $station->pollmode );
    $self->store_station_socket( $station );
}

=head2 remove_station

 Usage     : $receiver->remove_station( $station )
 Purpose   :
    Removes a station.
 Returns   : nothing
 Argument  : station-object
 Throws    : nothing

=cut

sub remove_station {
    my ($self, $station) = @_;
    croak "no station specified" unless $station;
    $self->poll->remove( $station->socket );
    $self->remove_station_socket( $station );
}

=head2 number_of_stations

 Usage     : $receiver->number_of_stations()
 Purpose   :
    Returns the number of stations.
 Returns   : number of stations
 Argument  : nothing
 Throws    : nothing
 See Also   : 

=cut

sub number_of_stations {
        my $self = shift;
        return $self->poll->handles
};

=head2 receive

 Usage     : $receiver->receive()
 Purpose   :
    Tries to receive next chunk from all stations.
    Call it in a loop.
 Returns   : nothing
 Argument  : nothing
 Throws    : nothing
 See Also   : 

=cut

sub receive {
    my $self = shift;

    if ($self->poll->handles) {
            $self->poll->poll( $self->timeout );
            my @ready = $self->poll->handles(POLLIN|POLLHUP|POLLERR|POLLOUT);
            unless ( scalar @ready ) {
		$self->timeout_all_stations();
            }

            foreach my $socket ( @ready ) {
                    my $station = $self->get_station_by_socket( $socket );
                    my $return = $station->receive();
                    if ( $return ) {
                           $self->poll->mask( $socket => $station->pollmode );
                    }
                    else {
                        $self->error_in_station( $station );
                    }
            }
    }
}

=head2 timeout

 Usage     : $receiver->timeout( 30 )
 Purpose   :
    Sets the timeout value for all stations.
 Returns   : nothing
 Argument  : timeout in seconds
 Throws    : nothing
 
 See Also   : timeout_all_stations

Overload the following methods:

=head2 init

 Usage     : init is called from new
 Purpose   :
    Initializes some values, create Poll-Object.
    Always call SUPER::init if you overload this method.
 Returns   : nothing
 Argument  : nothing
 Throws    : nothing
 See Also   : 

=cut

sub init {
    my $self = shift;
     $self->poll( IO::Poll->new()
        or croak "Couldn't create IO::Poll-Object" );
    $self->timeout(30) unless $self->timeout();
    $self->station_sockets( {} );
}

=head2 timeout_all_stations

 Usage     : timeout_all_stations is called if there is a network-timeout.
 Purpose   :
    overload it :)
    You can change the timeout-time with the 'timeout'-method.
 Returns   : nothing
 Argument  : nothing
 Throws    : nothing
 See Also   : timeout

=cut

sub timeout_all_stations {
    my ($self) = @_;
    return;
}

=head2 error_in_station

 Usage     : error_in_station is called if a station returns an error.
 Purpose   :
    overload it :)
    The default implementation removes the station from the receiver.
 Returns   : nothing
 Argument  : nothing
 Throws    : nothing
 See Also   : timeout

=cut

sub error_in_station {
    my ($self, $station) = @_;
    carp "error in station\n";
    $self->remove_station( $station );
}


=head1 BUGS

Doesn't work under Win32... please send patches :-)


=head1 SUPPORT



=head1 AUTHOR

	Nathanael Obermayer
	CPAN ID: nathanael
	natom-pause@smi2le.net

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut


sub get_station_by_socket {
    my ($self, $socket) = @_;
    return $self->station_sockets->{ $socket };
}

sub store_station_socket {
    my ($self, $station) = @_;
    $self->station_sockets->{ $station->socket } = $station;
}

sub remove_station_socket {
    my ($self, $station) = @_;
    $self->station_sockets->{ $station->socket } = undef;    
}


1; #this line is important and will help the module return a true value
__END__

