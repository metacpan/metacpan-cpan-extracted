package Net::Dopplr;

use strict;
use Carp;
use Net::Google::AuthSub;
use JSON::Any;
use URI;
use LWP::UserAgent;
use HTTP::Request::Common;

our $VERSION = '0.7';
our $AUTOLOAD;

=head1 NAME

Net::Dopplr - interface with Dopplr.com's web service

=head1 SYNOPSIS

    my $dopplr = Net::Dopplr->new($token);

    my $fellows = $dopplr->fellows('muttley');

    print "I share my trips with ".scalar(@{$fellows->{show_trips_to}})." people\n"; 
    print "I can see ".scalar(@{$fellows->{can_see_trips_of}})." people's trips\n"; 
    

=head1 GETTING A DEVELOPER TOKEN

This is a bit involved because Dopplr is still in beta.

First visit this URL

    https://www.dopplr.com/api/AuthSubRequest?next=http%3A%2F%2Fwww.example.com%2Fdopplrapi&scope=http%3A%2F%2Fwww.dopplr.com%2F&session=1

(Or you can replace next with you own web app). That will give you a developer token. 

You can then upgrade this to a permanent session token using the C<dopplr> 
utility shipped with this module or code similar to this

    use strict;
    use Net::Google::AuthSub;

    my $token = shift;
    my $auth = Net::Google::AuthSub->new( url => 'https://www.dopplr.com/api');
   
    $auth->auth('null', $token);
    my $sess    = $auth->session_token() || die "Couldn't get token: $@";
    print "Session token = $sess\n";

and then later

    my $dopplr = Net::Dopplr->new($sess);

You can then use the session token from that point forward.

=head1 METHODS

More information here

    http://dopplr.pbwiki.com/API+Resource+URLs

=cut

=head2 new <token> 

Requires a developer token or a session token.

=cut

sub new {
    my $class = shift;
    my $token = shift;
    my %opts  = @_;
    my $url   = $opts{url} || 'https://www.dopplr.com/api';
    my $ua    = LWP::UserAgent->new;
    my $json  = JSON::Any->new;
    my $auth  = Net::Google::AuthSub->new(url => $url);
    $auth->auth('null', $token);

    return bless { _auth => $auth, _ua => $ua, _json => $json, _url => $url }, $class;
}

my %methods = (
    fellows                 => 'traveller', 
    traveller_info          => 'traveller',
    trips_info              => 'traveller',
    future_trips_info       => 'traveller',
    fellows_travellingtoday => 'traveller',
    tag                     => 'traveller',
    location_on_date        => 'traveller',
 
    trip_info               => 'trip',
    add_trip_tags           => 'trip',
    add_trip_note           => 'trip',
    delete_trip             => 'trip',
    trip_coincidences       => 'trip',

    city_info               => 'city',
    add_trip                => 'city',
    trips_to_city           => 'city',

    search                  => 'search',
    city_search             => 'search',
    traveller_search        => 'search',

    tips                    => 'tip',
);

my %key_names = (
    traveller => 'traveller',
    trip      => 'trip_id',
    city      => 'geoname_id',
    search    => 'q',
    tip       => 'geoname_id',
);


my %post = map { $_ => 1 } qw(add_trip_tags 
                              add_trip_note 
                              delete_trip
                              add_trip
                              update_traveller
                              add_tip);
sub AUTOLOAD {
    my $self = shift;

    ref($self) or die "$self is not an object";

    my $name = $AUTOLOAD;
    $name =~ s/.*://;   # strip fully-qualified portion

    my $type = $methods{$name};
    die "Method $name not found\n" unless $type;

    if ($type eq 'traveller') {
        $self->_traveller($name, @_);
    } else {
        my $key  = $key_names{$type};
        my $val  = shift @_;
        if ('woeid' eq $val) {
            $key = $val;
            $val = shift @_;
        }
        croak "You must pass a $key to this method" unless defined $val;
        my %opts = @_;
        $self->call($name, { $key => $val, %opts });
    }
}

sub _traveller {
    my $self = shift;
    my $name = shift;
    my $val  = shift;
    my %opts = (defined $val)? ( traveller => $val ) : ();
    $self->call($name, { %opts });     
}



=head1 TRAVELLER METHODS

=cut

=head2 fellows [traveller]

Get people C<traveller> shares information with. 

If C<traveller> is not provided then defaults to 
the logged-in user.

=cut

=head2 traveller_info [traveller] 

Get information about a traveller.

If C<traveller> is not provided then defaults to
the logged-in user.

=cut

=head2 trips_info [traveller]

Get info about the trips of a traveller.

If C<traveller> is not provided then defaults to
the logged-in user.

=cut

=head2 future_trips_info [traveller]

Returns a list of all trips entered by the 
selected user that have yet to finish.

If C<traveller> is not provided then defaults to
the logged-in user.

=head2 fellows_travellingtoday [traveller]

Get which of C<traveller>'s fellows are travelling today.

If C<traveller> is not provided then defaults to
the logged-in user.

=cut

=head2 

=head2 tag <tag> [traveller].

Returns data about all trips with a specific tag.

For more information about tags see

    http://dopplr.pbwiki.com/Tags

If C<traveller> is not provided then defaults to
the logged-in user.

=cut


sub tag {
    my $self      = shift;
    my $tag       = shift || croak "You must pass a tag to this method";
    my $traveller = shift;
    my %opts      = ( tag => $tag );
    $opts{traveller} = $traveller if defined $traveller;
    $self->call('tag', { %opts });
}

=head2 location_on_date <date> [traveller]

Returns the location of a traveller on a particular date.

Date should be in ISO date format e.g

    2007-04-01

If C<traveller> is not provided then defaults to
the logged-in user.

=cut

sub location_on_date {
    my $self      = shift;
    my $date      = shift || croak "You must pass a date to this method";
    my $traveller = shift;
    my %opts      = ( date => $date );
    $opts{traveller} = $traveller if defined $traveller;
    $self->call('location_on_date', { %opts });
}

=head1 TRIP METHODS

=cut

=head2 trip_info <trip id>

Get info about a specific trip.

=cut

=head2 trip_coincidences <trip id>

Get coincidences for a given trip.

=cut


=head2 add_trip_tags <trip id> <tag[s]>

Add tags to a trip.

=cut

sub add_trip_tags {
    my $self    = shift;
    my $trip_id = shift || croak "You must pass a trip id to this method";
    my $tags    = join(" ", @_); 
    croak "You must pass at least one tag" unless length $tags;
    my %opts    = ( trip_id => $trip_id, tags => $tags );
    $self->call('add_trip_tags', { %opts });
}

=head2 add_trip_note <trip id> <note>

Add a note to a trip.

=cut

sub add_trip_note {
    my $self    = shift;
    my $trip_id = shift || croak "You must pass a trip id to this method";
    my $note    = shift || croak "You must pass a note body to this method";
    my %opts    = ( trip_id => $trip_id, body => $note );
    $self->call('add_trip_note', { %opts });
}

=head2 delete_trip <trip_id>

Delete a trip

=cut


=head1 CITY METHODS

=cut

=head2 city_info <geoname id>

Get info about a City.

Use search to get the geoname id. 

Alternatively pass in a woeid using

    $dopplr->city_info( woeid => $woeid );

=cut

=head2 add_trip <geoname id> <start> <finish>

Add a trip for the currently logged in user.

Use search to get the geoname id.

Alternatively pass in a woeid using

    $dopplr->add_trip( woeid => $woeid, $start, $finish );

Dates should be in ISO date format e.g

    2007-04-01

=cut

sub add_trip {
    my $self     = shift;
    my $use_woe  = 0;
    my $id       = shift || croak "You must pass a geoname id to this method";
    if ( 'woeid' eq $id ) { 
        $use_woe = 1;
        $id      = shift || croak "You must pass in a woe id to this method";
    } 
    my $start    = shift || croak "You must pass a start date to this method";
    my $finish   = shift || croak "You must pass a finish date to this method";
    my %opts     = ( start => $start, finish => $finish );
    $opts{($use_woe)? 'woeid' : 'geoname_id'} = $id; 
    $self->call('add_trip', { %opts }); 
}

=head2 trips_to_city <geoname id>

Get all your fellow travellers trips to a given city.

=cut

=head1 SEARCH METHODS

=head2 search <term>

Searches for travellers or cities.

=cut

=head2 city_search <term>

Searches for cities.

=cut

=head2 traveller_search <term>

Searches for travellers.

=cut


=head1 TIP METHODS

=head2 tips <geoname_id>

Get tips for a city. The returned tips will be tips that can be 
seen by the currently authenticated user, so may include private 
tips that only this user can see, as well as public tips on the city.

Alternatively pass in a woeid using

    $dopplr->tips( woeid => $woeid );

=cut

=head2 add_tip <geoname_id> <title> <review> [opt[s]]

Add a tip for a city. The response is the tip you just added.

Opts is a hash where the keys can be 

    public 
    url
    address
    tags

Alternatively pass in a woeid using

    $dopplr->add_tip( woeid => $woeid, $title, $review, %opts );

See http://dopplr.pbwiki.com/method%3Aadd_tip for more details.

=cut

sub add_tip {
    my $self     = shift;
    my $use_woe  = 0;
    my $id       = shift || croak "You must pass a geoname id to this method";
    if ( 'woeid' eq $id ) { 
        $use_woe = 1;
        $id      = shift || croak "You must pass in a woe id to this method";
    } 
    my $title   = shift || croak "You must pass a start date to this method";
    my $review  = shift || croak "You must pass a finish date to this method";
    my %opts    = ( @_, title => $title, review => $review );
    $opts{($use_woe)? 'woeid' : 'geoname_id'} = $id; 
    $self->call('add_tip', { %opts });
}

=head1 OTHER METHODS

=head2 update_traveller <opt[s]>

Update a traveller's details. 

Takes a hash with the new values. Possible keys are

    email
    forename
    surname
    password

=cut

sub update_traveller {
    my $self = shift;
    my %opts = @_;
    $self->call('update_traveller', { %opts });
}

=head1 GENERIC, FUTURE PROOF METHOD CALLING

=head2 call <name> <opts> [post]

This is the future proofing method. 

If there's any method I haven't implemented yet then 
you can simply provide the name of the method, the 
options as a hash ref and, optionally, whether it  
should be a POST request or not. So, for a theoretical
new method called C<throw_penguin> which throws a 
penguin at a traveller and is called as a POST

    $dopplr->call('throw_penguin', { traveller_id => $id }, 1);

and for C<get_penguins> which finds how many penguins have been 
thrown at a traveller and is called as a GET

    use Data::Dumper;
    my $data = $dopplr->call('get_penguins', { traveller_id => $id });
    print Dumper($data);

=cut

sub call {
    my $self = shift;
    my $name = shift;
    my $opts = shift;
    my $post = shift;
    my $type;
    if (defined $post) {
        $type =  ($post)? "POST" : "GET";
    } else {
        $type =  ($post{$name})? "POST" : "GET";
    }

    $opts->{format} = 'js';

    my $uri = URI->new($self->{_url});
    $uri->path($uri->path."/$name");
    my %params = $self->{_auth}->auth_params();
    my $req;
    if ("POST" eq $type) {
        $req = POST "$uri", [%$opts], %params;
    } else { 
        $uri->query_form(%$opts);
        $req = GET "$uri", %params;
    }
    
    my $res    = $self->{_ua}->request($req);
    die "Couldn't call $name : ".$res->status_line unless $res->is_success;

    return    $self->{_json}->decode($res->content);
}

sub DESTROY { }



=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright 2008, Simon Wistow

Distributed under the same terms as Perl itself.

=cut

1;
