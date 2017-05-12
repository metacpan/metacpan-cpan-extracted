package Purple::Client;

use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Request;
use URI::Escape;
use Purple;

sub new {
    my $class = shift;
    my %p = @_;

    # Use library directly if server_url is not set
    unless ($p{server_url}) {
        return Purple->new(store => $p{store});
    }

    my $self = {};
    $self->{server_url} = $p{server_url};
    bless ($self, $class);
    return $self;
}

sub getNext {
    my $self = shift;
    my $uri = shift;

    return _post( $self->{server_url}, $uri );
}

sub getNIDs {
    my $self = shift;
    my $url = shift;
    return _get( $self->{server_url}, $url );
}

sub getURL {
    my $self = shift;
    my $nid = shift;
    return _get( $self->{server_url}, $nid );
}

# XXX just one for now, API can do multi
sub deleteNIDs {
    my $self = shift;
    my $nid = shift;
    return _delete( $self->{server_url}, $nid );
}

sub updateURL {
    my $self = shift;
    my $new_uri = shift;
    my $nid     = shift;

    return _put($self->{server_url}, $new_uri, $nid);
}

sub _post {
    my $server  = shift;
    my $uri     = shift;
    my $nid     = shift;
    my $request = HTTP::Request->new( POST => $server );
    $uri = $uri . '#' . $nid if $nid;
    $request->content($uri);
    _respond_or_die($request);
}

sub _get {
    my $server = shift;
    my $arg    = shift;
    $arg = uri_escape($arg);
    my $request = HTTP::Request->new( GET => $server . '/' . $arg );
    _respond_or_die($request);
}

sub _delete {
    my $server  = shift;
    my $nid     = shift;
    my $request = HTTP::Request->new( DELETE => $server . '/' . $nid );
    _respond_or_die($request);
}

sub _put {
    my $server = shift;
    my $uri    = shift;
    my $nid    = shift;
    my $request
        = HTTP::Request->new( PUT => $server );
    $request->content( $uri . '#' . $nid );
    _respond_or_die($request);
}

sub _respond_or_die {
    my $request = shift;
    my $ua      = _userAgent();

    my $response = $ua->request($request);
    if ( $response->is_success ) {
        return $response->content;
    }

    # in real client eval, set errstr, whatever
    die $response->status_line;
}

# XXX more flesh here
sub _userAgent {
    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);

    # blah blah
    return $ua;
}

1;

=head1 NAME

Purple::Client - Client to L<Purple> and L<Purple::Server>

=head1 SYNOPSIS

    # use a remote Purple::Server
    my $client_net = Purple::Client->new(server_url => $SERVER_URL);

    # access a local store through the library
    my $client_lib = Purple::Client->new(store => 't/sql.lite');

=head1 METHODS

=head2 new(%options)

Valid %options include:

  server_url => 'SERVER_URL'  # for distributed Purple
  store => 'STORE'            # for local Purple

If no options specified, defaults to local SQLite store.

=head2 getNext($uri)

Gets the next available NID, assigning it $uri in the database.

=head2 getNIDs($uri)

Gets all NIDs associated with $uri.

=head2 getURL($nid)

Gets the URL associated with NID $nid.

=head2 deleteNIDs($nid)

Deletes the NID $nid.  Note that while the local API supports deleting
multiple NIDs at once, this does not (yet).

=head2 updateURL($url, $nid)

Updates the NID $nid with the URL $url.  Note that while the local API
supports updating multiple NIDs at once, this does not (yet).

=head1 AUTHOR

Chris Dent, E<lt>cdent@burningchrome.comE<gt>

Eugene Eric Kim, E<lt>eekim@blueoxen.comE<gt>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-purple@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Purple>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

(C) Copyright 2006 Blue Oxen Associates.  All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
