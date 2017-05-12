package Net::DMAP::Server;
use strict;
use warnings;
use POE;
use POE::Component::Server::HTTP 0.05; # for keep alive
use POE::Component::Server::HTTP;
use Net::Rendezvous::Publish;
use Net::DAAP::DMAP qw( dmap_pack );
use Sys::Hostname;
use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors(qw( debug port name path db_uuid tracks playlists
                              revision waiting_clients poll_interval ),
                          qw( httpd uri ),
                          # Rendezvous::Publish stuff
                          qw( publisher service ));
our $VERSION = '0.05';

=head1 NAME

Net::DMAP::Server - base class for D[A-Z]AP servers

=head1 SYNOPSIS

  package Net::DZAP::Server;
  use base qw( Net::DMAP::Server );
  sub protocol { 'dzap' }

  1;

  =head1 NAME

  Net::DZAP::Server - Digital Zebra Access Protocol (iZoo) Server

  =cut

=head1 DESCRIPTION

Net::DMAP::Server is a base class for implementing DMAP servers.  It's
probably not hugely useful to you directly, and you're better off
looking at Net::DPAP::Server or Net::DAAP::Server.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( {
        db_uuid          => '13950142391337751523',
        revision        => 42,
        tracks          => {},
        playlists       => {},
        waiting_clients => [],
        poll_interval   => 20,
        @_ } );
    $self->name( ref($self) ." " . hostname . " $$" ) unless $self->name;
    $self->port( $self->default_port ) unless $self->port;
    $self->find_tracks;
    #print Dump $self;
    $self->httpd( POE::Component::Server::HTTP->new(
        Port => $self->port,
        ContentHandler => { '/' => sub { $self->_handler(@_) } },
        StreamHandler => sub { $self->stream_handler(@_) },
       ) );

    my $publisher = Net::Rendezvous::Publish->new
      or die "couldn't make a Responder object";
    $self->publisher( $publisher );
    $self->service( $publisher->publish(
        name => $self->name,
        type => '_'.$self->protocol.'._tcp',
        port => $self->port,
        txt  => "Database ID=".$self->db_uuid."\x{1}Machine Name=".$self->name,,
       ) );

    POE::Session->create(
        inline_states => {
            _start       => sub {
                $_[KERNEL]->alarm( poll_changed => time + $self->poll_interval );
            },
            poll_changed => sub {
                $self->poll_changed;
                $_[KERNEL]->yield('_start');
            },
        });

    return $self;
}

sub stream_handler {
    my $self = shift;
    my ($request, $response) = @_;
}

sub _handler {
    my $self = shift;
    my ($request, $response) = @_;
    # always the same
    $response->code( RC_OK );
    $response->content_type( 'application/x-dmap-tagged' );

    local $self->{uri};
    $self->uri( $request->uri );
    print $request->uri, "\n" if $self->debug;

    # first match wins
    my @methods = (
        [ database_item      => qr{^/databases/\d+/items/(\d+)\.} ],
        [ database_items     => qr{^/databases/(\d+)/items} ],
        [ playlist_items     => qr{^/databases/(\d+)/containers/(\d+)} ],
        [ database_playlists => qr{^/databases/(\d+)/containers} ],
        [ databases          => qr{^/databases} ],
        [ server_info        => qr{^/server-info} ],
        [ content_codes      => qr{^/content-codes} ],
        [ update             => qr{^/update} ],
        [ login              => qr{^/login} ],
        [ logout             => qr{^/logout} ],
        [ ignore             => qr{^/this_request_is_simply_to_send_a_close_connection_header} ],
       );

    for (@methods) {
        my ($method, $pattern) = @$_;
        if (my @matched = ($self->uri->path =~ $pattern)) {
            #print "dispatching as $method\n" if $self->debug;
            $self->$method( $request, $response, @matched );
            return $response->code;
        }
    }

    print "Can't handle ".$self->uri->path."\n" if $self->debug;
    $response->code( 500 );
    return 500;
}


sub _dmap_pack {
    my $self = shift;
    my $dmap = shift;
    return dmap_pack $dmap;
}

sub find_tracks {
    die "override me";
}

sub database_item {
    my ($self, $request, $response) = @_;
    my $id = shift;
    $response->content( $self->tracks->{$1}->data );
}

sub content_codes {
    my ($self, $request, $response) = @_;
    $response->content($self->_dmap_pack(
        [[ 'dmap.contentcodesresponse' => [
            [ 'dmap.status'             => 200 ],
            map { [ 'dmap.dictionary' => [
                [ 'dmap.contentcodesnumber' => $_->{ID}   ],
                [ 'dmap.contentcodesname'   => $_->{NAME} ],
                [ 'dmap.contentcodestype'   => $_->{TYPE} ],
               ] ] } values %$Net::DAAP::DMAP::Types,
           ]]] ));
}

sub login {
    my ($self, $request, $response) = @_;
    $response->content( $self->_dmap_pack(
        [[ 'dmap.loginresponse' => [
            [ 'dmap.status'    => 200 ],
            [ 'dmap.sessionid' =>  42 ],
           ]]] ));
}

sub logout { }

sub ignore { }

sub update {
    my ($self, $request, $response) = @_;
    if ($self->uri =~ m{revision-number=(\d+)} && $1 >= $self->revision) {
        print "queueing $response\n" if $self->debug;
        push @{ $self->waiting_clients }, $response;
        $response->code( RC_WAIT );
        return;
    }
    $self->update_answer( $request, $response );
}

sub has_changed { 0 }

sub poll_changed {
    my $self = shift;
    if ($self->has_changed) {
        $self->revision( $self->revision + 1 );
        for my $response (@{ $self->waiting_clients }) {
            print "continuing $response\n" if $self->debug;
            $self->update_answer( undef, $response );
            $response->code( RC_OK );
            $response->continue;
        }
        $self->waiting_clients([]);
    }
}

sub update_answer {
    my ($self, $request, $response) = @_;

    $response->content( $self->_dmap_pack(
        [[ 'dmap.updateresponse' => [
            [ 'dmap.status'         => 200 ],
            [ 'dmap.serverrevision' =>  $self->revision ],
           ]]] ));
}

sub databases {
    my ($self, $request, $response) = @_;

    $response->content( $self->_dmap_pack(
        [[ 'daap.serverdatabases' => [
            [ 'dmap.status' => 200 ],
            [ 'dmap.updatetype' =>  0 ],
            [ 'dmap.specifiedtotalcount' =>  1 ],
            [ 'dmap.returnedcount' => 1 ],
            [ 'dmap.listing' => [
                [ 'dmap.listingitem' => [
                    [ 'dmap.itemid' =>  35 ],
                    [ 'dmap.persistentid' => $self->db_uuid ],
                    [ 'dmap.itemname' => $self->name ],
                    [ 'dmap.itemcount' => scalar keys %{ $self->tracks } ],
                    [ 'dmap.containercount' =>  1 ],
                   ],
                 ],
               ],
             ],
           ]]] ));
}

sub database_items {
    my ($self, $request, $response, $database_id) = @_;
    my $tracks = $self->_all_tracks;
    $response->content( $self->_dmap_pack(
        [[ 'daap.databasesongs' => [
            [ 'dmap.status' => 200 ],
            [ 'dmap.updatetype' => 0 ],
            [ 'dmap.specifiedtotalcount' => scalar @$tracks ],
            [ 'dmap.returnedcount' => scalar @$tracks ],
            [ 'dmap.listing' => $tracks ]
           ]]] ));
}

sub database_playlists {
    my ($self, $request, $response, $database_id) = @_;

    my $tracks = $self->_all_tracks;
    my $playlists = [
        [ 'dmap.listingitem' => [
            [ 'dmap.itemid'       => 39 ],
            [ 'dmap.persistentid' => '13950142391337751524' ],
            [ 'dmap.itemname'     => $self->name ],
            [ 'com.apple.itunes.smart-playlist' => 0 ],
            [ 'dmap.itemcount'    => scalar @$tracks ],
           ],
         ],
        map {
            [ 'dmap.listingitem' => [
                [ 'dmap.itemid'       => $_->dmap_itemid ],
                [ 'dmap.persistentid' => $_->dmap_persistentid ],
                [ 'dmap.itemname'     => $_->dmap_itemname ],
                [ 'com.apple.itunes.smart-playlist' => 0 ],
                [ 'dmap.itemcount'    => scalar @{ $_->items } ],
               ],
             ],
         } values %{ $self->playlists },
       ];
    $response->content( $self->_dmap_pack(
        [[ 'daap.databaseplaylists' => [
            [ 'dmap.status'              => 200 ],
            [ 'dmap.updatetype'          =>   0 ],
            [ 'dmap.specifiedtotalcount' =>   1 ],
            [ 'dmap.returnedcount'       =>   1 ],
            [ 'dmap.listing'             => $playlists ],
           ]]] ));
}

sub playlist_items {
    my ($self, $request, $response, $database_id, $playlist_id) = @_;

    my $playlist = $self->playlists->{ $playlist_id };

    my $tracks = $self->_all_tracks( $playlist ? @{ $playlist->items } : () );
    $response->content( $self->_dmap_pack(
        [[ 'daap.playlistsongs' => [
            [ 'dmap.status'              => 200 ],
            [ 'dmap.updatetype'          => 0 ],
            [ 'dmap.specifiedtotalcount' => scalar @$tracks ],
            [ 'dmap.returnedcount'       => scalar @$tracks ],
            [ 'dmap.listing'             => $tracks ]
           ]]] ));
}



sub item_field {
    my $self = shift;
    my $track = shift;
    my $field = shift;

    (my $method = $field) =~  s{[.-]}{_}g;
    # kludge
    if ($field =~ /dpap\.(thumb|hires)/) {
        $field = 'dpap.picturedata';
    }

    [ $field => eval { $track->$method() } ]
}

sub uniq {
    my %seen;
    return grep { !$seen{$_}++ } @_;
}

# some things are always present in the listings returned, whether you
# ask for them or not
sub _always_answer {
    qw( dmap.itemkind dmap.itemid dmap.itemname );
}

sub _response_fields {
    my $self = shift;

    my $meta = { $self->_uri_arguments }->{meta} || '';
    my @fields = uniq $self->_always_answer, split /(?:,|%2C)/, $meta;
    return @fields;
}

sub _uri_arguments {
    my $self = shift;
    my @chunks = split /&/, $self->uri->query || '';
    return map { split /=/, $_, 2 } @chunks;
}

sub _all_tracks {
    my $self = shift;

    # cheat for playlist support
    my @tracks;
    if (@_) {
        @tracks = @_;
    }
    else {
        # sometimes, all isn't really all (DPAP)
        my $query = { $self->_uri_arguments }->{query} || '';
        @tracks = $query =~ /dmap\.itemid/
          ? map { $self->tracks->{$_} } $query =~ /dmap\.itemid:(\d+)/g
          : values %{ $self->tracks };
    }

    my @fields = $self->_response_fields;
    my @results;
    for my $track (@tracks) {
        push @results, [ 'dmap.listingitem' => [
            map { $self->item_field( $track => $_ ) } @fields ] ];
    }
    return \@results;
}



=head1 BUGS

The Digital Zebra Access Protocol does not exist, so you'll have to
manually acquire your own horses and paint them.


=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net>

=head1 COPYRIGHT

Copyright 2004, 2005, 2006 Richard Clamp.  All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

Net::DAAP::Server, Net::DPAP::Server

=cut

1;
