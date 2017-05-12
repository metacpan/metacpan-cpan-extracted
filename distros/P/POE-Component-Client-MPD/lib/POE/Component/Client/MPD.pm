#
# This file is part of POE-Component-Client-MPD
#
# This software is copyright (c) 2007 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.010;
use strict;
use warnings;

package POE::Component::Client::MPD;
# ABSTRACT: full-blown poe-aware mpd client library
$POE::Component::Client::MPD::VERSION = '2.001';
use Audio::MPD::Common::Stats;
use Audio::MPD::Common::Status;
use Carp;
use List::AllUtils qw{ any };
use Moose;
use MooseX::Has::Sugar;
use MooseX::POE;
use MooseX::SemiAffordanceAccessor;
use MooseX::Types::Moose qw{ Int Str };
use POE;
use Readonly;

use POE::Component::Client::MPD::Commands;
use POE::Component::Client::MPD::Collection;
use POE::Component::Client::MPD::Connection;
use POE::Component::Client::MPD::Message;
use POE::Component::Client::MPD::Playlist;

Readonly my $K => $poe_kernel;


# -- attributes


has host           => ( ro, lazy_build, isa=>Str );
has password       => ( ro, lazy_build );
has port           => ( ro, lazy_build, isa=>Int );

has alias          => ( ro, isa=>Str, default=>'mpd' );
has status_msgs_to => ( ro, isa=>Str, predicate=>'has_peer' );
has version        => ( rw, isa=>Str );

has _collection    => ( ro, lazy_build, isa=>'POE::Component::Client::MPD::Collection' );
has _commands      => ( ro, lazy_build, isa=>'POE::Component::Client::MPD::Commands'   );
has _playlist      => ( ro, lazy_build, isa=>'POE::Component::Client::MPD::Playlist'   );

has _socket        => ( rw, isa=>Str );



# -- builder & initializers

#
# my ($passwd, $host, $port) = _parse_env_var();
#
# parse MPD_HOST environment variable, and extract its components. the
# canonical format of MPD_HOST is passwd@host:port.
#
sub _parse_env_var {
    return (undef, undef, undef) unless defined $ENV{MPD_HOST};
    return ($1, $2, $3)    if $ENV{MPD_HOST} =~ /^([^@]+)\@([^:@]+):(\d+)$/; # passwd@host:port
    return ($1, $2, undef) if $ENV{MPD_HOST} =~ /^([^@]+)\@([^:@]+)$/;       # passwd@host
    return (undef, $1, $2) if $ENV{MPD_HOST} =~ /^([^:@]+):(\d+)$/;          # host:port
    return (undef, $ENV{MPD_HOST}, undef);
}

sub _build_host     { return ( _parse_env_var() )[1] || 'localhost'; }
sub _build_port     { return $ENV{MPD_PORT}     || ( _parse_env_var() )[2] || 6600; }
sub _build_password { return $ENV{MPD_PASSWORD} || ( _parse_env_var() )[0] || '';   }

sub _build__collection { POE::Component::Client::MPD::Collection->new(mpd=>$_[0]); }
sub _build__commands   { POE::Component::Client::MPD::Commands  ->new(mpd=>$_[0]); }
sub _build__playlist   { POE::Component::Client::MPD::Playlist  ->new(mpd=>$_[0]); }


# -- public methods


sub spawn {
    my $self = shift->new(@_);
    return $self->{session_id};
}



# -- private methods

sub _dispatch {
    my ($self, $event, $msg) = @_;

    # dispatch the event.
    if ( $event =~ /^pl\.(.*)$/ ) {
        # playlist commands
        my $meth = "_do_$1";
        $self->_playlist->$meth($msg);
    } elsif ( $event =~ /^coll\.(.*)$/ ) {
        # collection commands
        my $meth = "_do_$1";
        $self->_collection->$meth($msg);
    } else {
        # basic commands
        my $meth = "_do_$event";
        $self->_commands->$meth($msg);
    }
}


#
# $mpd->_send_to_mpd( $msg );
#
# send $msg to mpd using pococm.
#
sub _send_to_mpd {
    my ($self, $msg) = @_;
    $K->post( $self->_socket => send => $msg );
}




# -- public events.


#
# catch-all handler for pococm events that drive mpd.
#
event _default => sub {
    my ($self, $event, $params) = @_[OBJECT, ARG0, ARG1];

    # check if event is handled.
    my @events_commands = qw{
        password version kill updatedb urlhandlers
        volume output_enable output_disable
        stats status current song songid
        repeat fade random
        play playid pause stop next prev seek seekid
    };
    my @events_playlist = qw{
        pl.as_items pl.items_changed_since
        pl.add pl.delete pl.deleteid pl.clear pl.crop
        pl.shuffle pl.swap pl.swapid pl.move pl.moveid
        pl.load pl.save pl.rm
    };
    my @events_collection = qw{
        coll.all_items coll.all_items_simple coll.items_in_dir
        coll.all_albums coll.all_artists coll.all_titles coll.all_files
        coll.song coll.songs_with_filename_partial
        coll.albums_by_artist coll.songs_by_artist coll.songs_by_artist_partial
            coll.songs_from_album coll.songs_from_album_partial
            coll.songs_with_title coll.songs_with_title_partial
    };
    my @ok_events = ( @events_commands, @events_playlist, @events_collection );
    return unless any { $event eq $_ } @ok_events;

    # create the message that will hold
    my $msg = POE::Component::Client::MPD::Message->new( {
        _from       => $_[SENDER]->ID,
        request    => $event,  # /!\ $_[STATE] eq 'default'
        params     => $params,
        #_commands  => <to be set by handler>
        #_cooking   => <to be set by handler>
        #_transform => <to be set by handler>
        #_post      => <to be set by handler>
    } );

    # dispatch the event so it is handled by the correct object/method.
    $self->_dispatch($event, $msg);
};




event disconnect => sub {
    my $self = shift;
    $K->alias_remove( $self->alias );           # refcount--
    $K->post( $self->_socket, 'disconnect' );   # pococm-conn
};


# -- protected events fired by pococm-conn

#
# event: mpd_connect_error_retriable( $reason )
# event: mpd_connect_error_fatal( $reason )
event mpd_connect_error_retriable => \&_mpd_connect_error;
event mpd_connect_error_fatal     => \&_mpd_connect_error;

# Called when pococm-conn could not connect to a mpd server. It can be
# either retriable, or fatal. In bth case, we just need to forward the
# error to our peer session.
#
sub _mpd_connect_error {
    my ($self, $reason) = @_[OBJECT, ARG0];

    return unless $self->has_peer;
    $K->post($self->status_msgs_to, 'mpd_connect_error', $reason);
}


#
# event: mpd_connected( $version )
#
# Called when pococm-conn made sure we're talking to a mpd server.
#
event mpd_connected => sub {
    my ($self, $version) = @_[OBJECT, ARG0];
    $self->set_version( $version );

    return unless $self->has_peer;
    $K->post($self->status_msgs_to, 'mpd_connected');
    $K->yield(password => $self->password) if $self->password;
    # FIXME: send status information to peer
};



#
# event: mpd_disconnected()
#
# Called when pococm-conn got disconnected by mpd.
#
event mpd_disconnected => sub {
    my ($self, $version) = @_[OBJECT, ARG0];
    return unless $self->has_peer;
    $K->post($self->status_msgs_to, 'mpd_disconnected');
};



#
# Event: mpd_data( $msg )
#
# Received when mpd finished to send back some data.
#
event mpd_data => sub {
    my ($self, $msg) = @_[OBJECT, ARG0];

    # transform data if needed.
    if ( defined $msg->_transform ) {
        if ( $msg->_transform eq "as_scalar" ) {
            my $data = $msg->_data->[0];
            $msg->_set_data($data);
        } elsif ( $msg->_transform eq "as_stats" ) {
            my %stats = @{ $msg->_data };
            my $stats = Audio::MPD::Common::Stats->new( \%stats );
            $msg->_set_data($stats);
        } elsif ( $msg->_transform eq "as_status" ) {
            my %status = @{ $msg->_data };
            my $status = Audio::MPD::Common::Status->new( \%status );
            $msg->_set_data($status);
        }
    }


    # check for post-callback.
    if ( defined $msg->_post ) {
        my $event = $msg->_post;    # save postback.
        $msg->_set_post( undef );   # remove postback.
        $self->_dispatch($event, $msg);
        return;
    }

    # send result.
    $K->post($msg->_from, 'mpd_result', $msg, $msg->_data);
};


#
# Event: mpd_error( $msg, $errstr )
#
# Received when mpd didn't understood a command.
#
event mpd_error => sub {
    my ($msg, $errstr) = @_[ARG0, ARG1];

    $msg->set_status(0); # failure
    $K->post( $msg->_from, 'mpd_error', $msg, $errstr );
};



# -- private events

#
# Event: _start( \%params )
#
# Called when the poe session gets initialized. Receive a reference
# to %params, same as spawn() received.
#
sub START {
    my $self = shift;
    $K->alias_set( $self->alias );    # refcount++

    # create the connection to mpd. we *cannot* do this with a
    # lazy_build, otherwise the connection will be started too late...
    my $socket = POE::Component::Client::MPD::Connection->spawn( {
        host     => $self->host,
        port     => $self->port,
        password => $self->password,
        id       => $self->alias,
    } );
    $self->_set_socket( $socket );
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

POE::Component::Client::MPD - full-blown poe-aware mpd client library

=head1 VERSION

version 2.001

=head1 SYNOPSIS

    use POE qw{ Component::Client::MPD };
    POE::Component::Client::MPD->spawn( {
        host           => 'localhost',
        port           => 6600,
        password       => 's3kr3t',  # mpd password
        alias          => 'mpd',     # poe alias
        status_msgs_to => 'myapp',   # session to send status info to
    } );

    # ... later on ...
    $_[KERNEL]->post( mpd => 'next' );

=head1 DESCRIPTION

POCOCM gives a clear message-passing interface (sitting on top of POE)
for talking to and controlling MPD (Music Player Daemon) servers. A
connection to the MPD server is established as soon as a new POCOCM
object is created.

Commands are then sent to the server as messages are passed.

=head1 ATTRIBUTES

=head2 host

The hostname where MPD is running. Defaults to environment var
C<MPD_HOST>, then to 'localhost'. Note that C<MPD_HOST> can be of
the form C<password@host:port> (each of C<password@> or C<:port> can
be omitted).

=head2 port

The port that MPD server listens to. Defaults to environment var
C<MPD_PORT>, then to parsed C<MPD_HOST> (cf above), then to 6600.

=head2 password

The password to access special MPD functions. Defaults to environment
var C<MPD_PASSWORD>, then to parsed C<MPD_HOST> (cf above), then to
empty string.

=head2 alias

A string to alias the newly created POE session. Defaults to C<mpd>.

=head2 status_msgs_to

A session (name or id) to whom to send connection status to. Optional,
although recommended. No default. When this is done, pococm will send
*additional* events to the session, such as: C<mpd_connected> when
pococm is connected, C<mpd_disconnected> when pococm is disconnected,
etc. You thus need to register some handlers for those events.

=head1 METHODS

=head2 my $id = POE::Component::Client::MPD->spawn( \%params );

This method will create a POE session responsible for communicating with
mpd. It will return the poe id of the session newly created. You can
tune it by passing some arguments as a hash reference. See the
attributes for allowed values.

=head1 PUBLIC EVENTS ACCEPTED

=head2 MPD-related events

The goal of a POCOCM session is to drive a remote MPD server. This can
be achieved by a lot of events. Due to their sheer number, they have
been regrouped logically in modules.

However, note that to use those events, you need to send them to the
POCOCM session that you created with C<spawn()> (see above). Indeed, the
logical split is only internal: you are to use the same peer.

For a list of public events that update and/or query MPD, see embedded
pod in:

=over 4

=item * L<POE::Component::Client::MPD::Commands> for general commands

=item * L<POE::Component::Client::MPD::Playlist> for playlist-related
commands. Those events begin with C<pl.>.

=item * L<POE::Component::Client::MPD::Collection> for collection-
related commands. Those events begin with C<coll.>.

=back

=head2 disconnect( )

Request the POCOCM to be shutdown. Leave mpd running. Generally sent
when one wants to exit her program.

=for Pod::Coverage::TrustPod START

=head1 EVENTS FIRED

A POCOCM session will fire events, either to answer an incoming event,
or to inform about some changes regarding the remote MPD server.

=head2 Answer events

For each incoming event received by the POCOCM session, it will fire
back one of the following answers:

=over 4

=item * mpd_result( $msg, $answer )

Indicates a success. C<$msg> is a
L<POE::Component::Client::MPD::Message> object with the original
request, to identify the issued command (see
L<POE::Component::Client::MPD::Message> pod for more information). Its
C<status()> attribute is true, further confirming success.

C<$answer> is what has been answered by the MPD server. Depending on the
command, it can be either:

=over 4

=item * C<undef>: commands C<play>, etc.

=item * an L<Audio::MPD::Common::Stats> object: command C<stats>

=item * an L<Audio::MPD::Common::Status> object: command C<status>

=item * an L<Audio::MPD::Common::Item> object: commands C<song>, etc.

=item * an array reference: commands C<coll.files>, etc.

=item * etc.

=back

Refer to the documentation of each event to know what type of answer you
can expect.

=item * mpd_error( $msg, $errstr )

Indicates a failure. C<$msg> is a
L<POE::Component::Client::MPD::Message> object with the original
request, to identify the issued command (see
L<POE::Component::Client::MPD::Message> pod for more information). Its
C<status()> attribute is false, further confirming failure.

C<$errstr> is what the error message as returned been answered by the
MPD server.

=back

=head2 Auto-generated events

If you supplied the C<status_msgs_to> attribute, the following events
are fired to this peer by pococm:

=over 4

=item * mpd_connect_error( $reason )

Called when pococm-conn could not connect to a mpd server. It can be
either retriable, or fatal. Check C<$reason> for more information.

=item * mpd_connected( )

Called when pococm-conn made sure we're talking to a mpd server.

=item * mpd_disconnected( )

Called when pococm-conn has been disconnected from mpd server.

=back

=head1 SEE ALSO

You can find more information on the mpd project on its homepage at
L<http://www.musicpd.org>, or its wiki L<http://mpd.wikia.com>. You may
want to have a look at L<Audio::MPD>, a non-L<POE> aware module to
access MPD.

You can look for information on this module at:

=over 4

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Component-Client-MPD>

=item * See open / report bugs

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-Client-MPD>

=item * Mailing-list (same as L<Audio::MPD>)

L<http://groups.google.com/group/audio-mpd>

=item * Git repository

L<http://github.com/jquelin/poe-component-client-mpd>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Component-Client-MPD>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Component-Client-MPD>

=back

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
