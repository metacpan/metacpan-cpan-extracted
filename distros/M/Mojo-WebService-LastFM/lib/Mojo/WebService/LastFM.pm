package Mojo::WebService::LastFM;

use Moo;
use strictures 2;
use Mojo::UserAgent;
use Mojo::Promise;
use Mojo::Exception;
use Carp;
use namespace::clean;

our $VERSION = '0.02';


has 'api_key'   => ( is => 'ro' );
has 'ua'        => ( is => 'lazy', builder => sub 
{ 
    my $self = shift;
    my $ua = Mojo::UserAgent->new; 
    $ua->transactor->name("Mojo-WebService-LastFM");
    $ua->connect_timeout(5);
    return $ua;
});
has 'base_url'  => ( is => 'lazy', default => 'http://ws.audioscrobbler.com/2.0' );

sub recenttracks
{
    my ($self, $params, $callback) = @_;
    croak '$username is undefined' unless defined $params->{'username'};

    my $limit = $params->{'limit'} // 1;

    my $url = $self->base_url . 
    '/?method=user.getrecenttracks' .
    '&user=' . $params->{'username'} . 
    '&api_key=' . $self->api_key . 
    '&format=json' . 
    '&limit=' . $limit;

    unless ( ref $_[-1] eq 'CODE' )
    {
        my $tx = $self->ua->get($url);
        return ( $tx->res ? $tx->res->json : $tx->error );
    }

    $self->ua->get($url => sub
    {
        my ($ua, $tx) = @_;
        $callback->($tx->error) unless defined $tx->result;

        my $json = $tx->res->json;
        $callback->(Mojo::Exception->new('json response is undefined')) unless defined $json;

        $callback->($json);
    });
}

sub recenttracks_p
{
    my ($self, $params) = @_;

    my $promise = Mojo::Promise->new;
    $self->recenttracks($params, sub { $promise->resolve(shift) });
    return $promise;
}

sub nowplaying
{
    my ($self, $params, $callback) = @_;
    my $username;
    if ( ref $params eq 'HASH' )
    {
        croak 'username is undefined' unless exists $params->{'username'};
        $username = $params->{'username'};
    }
    elsif ( ref \$params eq 'SCALAR' ) 
    {
        $username = $params;
    }
    else
    {
        croak 'Invalid params format. Accept Hashref or Scalar.';
    }

    my $np;

    unless ( ref $_[-1] eq 'CODE' )
    {
        my $json = $self->recenttracks({ 'username' => $username, 'limit' => 1 });
        if ( exists $json->{'recenttracks'}{'track'}[0] )
        {
            $np = _simplify_json($json);
            return $np;
        }
        else
        {
            return Mojo::Exception->new('Error: Response missing now-playing information.');
        }
    }

    $self->recenttracks_p({ 'username' => $username, 'limit' => 1 })->then(sub
    {
        my $json = shift;
        $callback->(Mojo::Exception->new('$json is undefined')) unless defined $json;

        if ( exists $json->{'recenttracks'}{'track'}[0] )
        {
            $np = _simplify_json($json);
            $callback->($np);
        }
        else
        {
            $callback->(Mojo::Exception->new('Error: Response missing now-playing information.'));
        }
    });
}

# Convert the recenttracks JSON object to the simplified nowplaying object.
sub _simplify_json
{
    my $json = shift;
    my $track = $json->{'recenttracks'}{'track'}[0];
    
    my $np = {
        'artist' => $track->{'artist'}{'#text'},
        'album'  => $track->{'album'}{'#text'},
        'title'  => $track->{'name'},
        'date'   => $track->{'date'},
        'image'  => $track->{'image'},
    };
    
    return $np;
}

sub nowplaying_p
{
    my ($self, $params) = @_;
    my $promise = Mojo::Promise->new;

    $self->nowplaying($params, sub{ $promise->resolve(shift) });
    return $promise;
}

sub info
{
    my ($self, $user, $callback) = @_;
    croak 'user is undefined' unless defined $user;

    my $url = $self->base_url . 
    '/?method=user.getinfo' . 
    '&user=' . $user .
    '&api_key=' . $self->api_key .
    '&format=json';
    
    unless ( ref $_[-1] eq 'CODE' )
    {
        my $tx = $self->ua->get($url);
        return ($tx->result ? $tx->res->json : $tx->error);
    }

    $self->ua->get($url => sub
    {
        my ($ua, $tx) = @_;
        my  $json = $tx->res->json;
        $callback->($json);
    });
}

sub info_p
{
    my ($self, $user) = @_;
    my $promise = Mojo::Promise->new;

    $self->info($user, sub { $promise->resolve(shift) });
    
    return $promise;
}

1;

=encoding utf8

=head1 NAME

Mojo::WebService::LastFM - Non-blocking recent tracks information from Last.FM

=head1 SYNOPSIS

    use Mojo::WebService::LastFM;
    use Data::Dumper;

    my $user = 'vsTerminus';
    my $last = Mojo::WebService::LastFM->new('api_key' => 'abc123');

    # Get currently playing or last played track using a callback, passing username as a scalar,
    # and dump the resulting hashref to screen using Data::Dumper
    $last->nowplaying($user, sub { say Dumper(shift) });
    
    # Get currently playing or last played track using a promise, passing username in a hashref
    $last->nowplaying_p({
        'username' => $user
    })->then(sub
    {
        my $np = shift;
        if ( exists $np->{'date'} )
        {
            say $user . ' last listened to ' . $np->{'title'} . ' by ' . $np->{'artist'} . ' from ' . $np->{'album'} . ' at ' . $np->{'date'};
        }
        else
        {
            say $user . ' is currently listening to ' . $np->{'title'} . ' by ' . $np->{'artist'} . ' from ' . $np->{'album'};
        }
    })->catch(sub
    {
        my $err = shift;
        die $err->message;
    });
    
    # Get a complete recent tracks payload using a callback
    # Print a formatted string of values
    $last->recenttracks({ 'username' => $user }, sub
    {
        my $json = shift;
        my $track = $json->{'recenttracks'}{'track'}[0];
        my $artist = $track->{'artist'}{'#text'};
        my $album = $track->{'album'}{'#text'};
        my $title = $track->{'name'};
        my $date = $track->{'date'};
        my $img = $track->{'image'};

        my $when = ( defined $date ? 'Last played' : 'Now playing' );
        say "$when $artist - $album - $title";
    });
    
    # Get a complete recent tracks payload using a promise
    # Dump the hashref to screen with Data::Dumper
    $last->recenttracks_p({ 'username' => $user })->then(sub{ say Dumper(shift) });

=head1 DESCRIPTION

L<Mojo::WebService::LastFM> is a way to request currently playing or recently played song information from Last.FM. Support exists for blocking calls or non-blocking with callbacks or promises - your choice.

It also provides the option to either fetch the entire JSON return object as a hashref, or to fetch a simplified hashref which contains only the currently playing or last played song info. The latter is easier to work with if you just want to display the currently playing song.

=head1 ATTRIBUTES

=head2 api_key

You will need an API Key for Last.FM, which you can get from L<the Last.FM API page|https://www.last.fm/api/account/create>.

You will receive an API Key and an API Secret. Each will be a string of base-16 numbers (0-9a-f).

You don't need the API Secret for anything in this module (currently), but make sure when you get it you record it somewhere (eg your password vault) because LastFM won't show it to you again and you may need it in the future.

=head2 ua

A Mojo::UserAgent object is used to make all of the HTTP calls asynchronously.

=head2 base_url

This is the base URL for the Last.FM API site. It defaults to 'http://ws.audioscrobbler.com/2.0'.

API call URLs are made by appending endpoints to this base string.

=head1 METHODS

L<Mojo::WebService::LastFM> implements the following methods

=head2 recenttracks

Request the complete 'recenttracks' JSON structure from Last.FM

Non-Blocking: Takes a hashref and a callback, returns nothing.
Blocking: Takes a hashref, returns a hashref

The parameters must contain at least a 'username' value, but may also specify a 'limit' value for the number of recent tracks to retrieve.

The callback, if defined, should be a sub. recenttracks will call this sub and pass it the json object it got from the API.


    $lastfm->recenttracks({'username' => $some_user, 'limit' => 1}, sub { my $json = shift; ... }); # Non-Blocking

    my $json = $lastfm->recenttracks({'username' => $some_user, 'limit' => 2}); # Blocking

=head2 recenttracks_p

Version of recenttracks which accepts a params hashref and returns a L<Mojo::Promise>

    $lastfm->recenttracks_p({'username' => $another_user})->then(sub{ say Dumper(shift) })->catch(sub{ say Dumper(shift) });

=head2 nowplaying

Return only the currently playing track or the last played track in a simplified object structure.

Takes a username either as a scalar or as a hashref with the 'username' key and a callback sub.
Sends the resulting JSON payload as a hashref to the callback.

Alternatively takes just a username, makes a blocking call, and returns the JSON payload as a hashref.

The response includes the Artist, Album, Title, and Album Art URL. If it is not the currently playing track it will also include the date/time of when the last track was played.
Checking for the existence of the date key is the simplest way to determine if the song is currently playing or not.

    # As scalar
    $lastfm->nowplaying('SomeUser1234', sub { my $json = shift; say "Now Playing: " . $json->{'artist'} . " - " . $json->{'title'} ; });

    # As hashref
    $lastfm->nowplaying({'username' => 'SomeUser1234'}, sub { exists shift->{'date'} ? say "Last Played" : say "Currently Playing" });

    # Blocking
    my $json = $lastfm->nowplaying('SomeUser5678');

=head2 nowplaying_p

Promise version of nowplaying.

Takes a username as a scalar or as a hashref, returns a L<Mojo::Promise>

    $lastfm->nowplaying_p('SomeUser5678')->then(sub{ say Dumper(shift) });

=head2 info

Returns user profile info for the specified user.

Accepts a username as a string and a callback sub.
Sends the resulting JSON payload as a hashref to the callback.

Alternatively accepts just a username and returns the JSON payload after making a blocking call.

    $lastfm->info($username, sub { say Dumper(shift) }); # Non-Blocking

    my $json = $lastfm->info($username); # Blocking

=head2 info_p

Promise version of info. Takes a username as a string, returns a L<Mojo::Promise>

    $lastfm->info_p($user)->then(sub{ say Dumper(shift) });

=head1 BUGS

Report any issues on the public bug tracker.

=head1 AUTHOR

Travis Smith <tesmith@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Travis Smith.

This is free software, licensed under:

  The MIT (X11) License

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=cut
