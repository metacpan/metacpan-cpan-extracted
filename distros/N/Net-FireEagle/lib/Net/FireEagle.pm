package Net::FireEagle;

# Client library for FireEagle
use strict;
use base qw(Net::OAuth::Simple);

our $VERSION = '1.6';

# FireEagle Endpoint URLs
our $REQUEST_TOKEN_URL = 'https://fireeagle.yahooapis.com/oauth/request_token';
our $AUTHORIZATION_URL = 'https://fireeagle.yahoo.net/oauth/authorize';
our $ACCESS_TOKEN_URL  = 'https://fireeagle.yahooapis.com/oauth/access_token';
our $QUERY_API_URL     = 'https://fireeagle.yahooapis.com/api/0.1/user';
our $UPDATE_API_URL    = 'https://fireeagle.yahooapis.com/api/0.1/update';
our $LOOKUP_API_URL    = 'https://fireeagle.yahooapis.com/api/0.1/lookup';
our $WITHIN_API_URL    = 'https://fireeagle.yahooapis.com/api/0.1/within';
our $RECENT_API_URL    = 'https://fireeagle.yahooapis.com/api/0.1/recent';


=head1 NAME

Net::FireEagle - access Yahoo's new FireEagle location service

=head1 SYNOPSIS

    # Set up Fire Eagle oauth
    my $fe  = Net::FireEagle->new( consumer_key    => $consumer_key, 
                                   consumer_secret => $consumer_secret );

    # Resume previous Fire Eagle oauth, feed access token and secret
    my $fe2 = Net::FireEagle->new( consumer_key        => $consumer_key, 
                                   consumer_secret     => $consumer_secret, 
                                   access_token        => $access_token, 
                                   access_token_secret => $access_token_secret );

    # Send this to user to grant authorization for this app
    my $auth_url = $fe->get_authorization_url;
    # ... and request an access token
    # Note: you can save these in DB to restore previous Fire Eagle oauth session
    my ($access_token, $access_token_secret) = $fe->request_access_token;

    # Get them back
    my $access_token = $fe->access_token;
    my $access_token_secret = $fe->access_token_secret;

    # in the case of a web app, you want to save the request tokens
    # (and/or set them)
    my $request_token = $fe->request_token;
    my $request_token_secret = $fe->request_token_secret;
    $fe->request_token( $request_token );
    $fe->request_token_secret( $request_token_secret );

    # Can't query or update location without authorization
    my $loc = $fe->location;                     # returns xml
    my $loc = $fe->location( format => 'xml'  ); # returns xml
    my $loc = $fe->location( format => 'json' ); # returns json

    # returns result on success. dies or returns undef on failure    
    my $return = $fe->update_location( "500 Third St., San Francisco, CA" );

    # Find a location. Returns either xml or json
    my $return = $fe->lookup_location( "Pensacola" );

=head1 ABOUT

Fire Eagle is a site that stores information about your location. With 
your permission, other services and devices can either update that 
information or access it. By helping applications respond to your 
location, Fire Eagle is designed to make the world around you more 
interesting! Use your location to power friend-finders, games, local 
information services, blog badges and stuff like that...

For more information see http://fireeagle.yahoo.net/

=head1 AUTHENTICATION

For more information read this

    http://fireeagle.yahoo.net/developer/documentation/getting_started

but, in short you have to first get an API key from the FireEagle site. 
Then using this consumer key and consumer secret you have to 
authenticate the relationship between you and your user. See the script 
C<fireagle> packaged with this module for an example of how to do this.

=head1 SIMPLE DAILY USAGE AND EXAMPLE CODE

The script C<fireeagle> shipped with this module gives you really
quick access to your FireEagle account - you can use it to simply 
query and update your location.

It also serves as a pretty good example of how to do desktop app
authentication and how to use the API. 

=head1 METHODS

=cut

=head2 new <opts>

Create a new FireEagle object. This must have the options

=over 4

=item consumer_key 

=item consumer_secret

=back

which you can get at http://fireeagle.yahoo.net/developer/manage

then, when you have your per-user authentication tokens (see above) you 
can supply

=over 4

=item access_token

=item access_token_secret

=back

Alternatively when you create a new web-based application, a general-purpose 
access token is issued to you along with your application key and secret. You
can get them at http://fireeagle.yahoo.net/developer/manage.

They are tied to your application and allow your application to make 
general-purpose API method calls (often batch-style) to Fire Eagle.

You can read about them at

    http://fireagle.yahoo.net/developer/documentation/using_oauth#feaccesstokens



You can pass them in using the param

=over 4

=item general_token

=item general_token_secret

=back

=cut

sub new {
    my $proto  = shift;
    my $class  = ref $proto || $proto;
    my %tokens = @_;

    return $class->SUPER::new( tokens => \%tokens,
                               urls   => {
                                authorization_url => $AUTHORIZATION_URL,
                                request_token_url => $REQUEST_TOKEN_URL,
                                access_token_url  => $ACCESS_TOKEN_URL,
                            });        

}

=head2 location [opt[s]

Get the user's current location.

Options are passed in as a hash and may be one of

=over 4

=item format

Either 'xml' or 'json'. Defaults to 'xml'.

=back

=cut

sub location {
    my $self = shift;
    my %opts = @_;

    my $url = $QUERY_API_URL; 
    $url   .= '.'.$opts{format} if defined $opts{format};

    return $self->_make_restricted_request($url, 'GET');
}

=head2 update_location <location> <opt[s]>

Takes a free form string with the new location.

Return the result of the update in either xml or json
depending on C<opts>.

The location can either be a plain string or a hash reference containing
location parameters as described in

    http://fireeagle.yahoo.net/developer/documentation/location#locparams

=cut

sub update_location {
    my $self     = shift;
    my $location = shift;
    my %opts     = @_;
   
    my %extras   = $self->_munge('address', $location);
    
    my $url      = $UPDATE_API_URL; 
    $url        .= '.'.$opts{format} if defined $opts{format};
    
    return $self->_make_restricted_request($url, 'POST', %extras);
}

=head2 lookup_location <query> <opt[s]>

Disambiguates potential values for update. Results from lookup can be 
passed to update to ensure that Fire Eagle will understand how to parse 
the location parameter.

Return the result of the update in either xml or json
depending on C<opts>.

The query can either be a plain string or a hash reference containing
location parameters as described in

    http://fireeagle.yahoo.net/developer/documentation/location#locparams

=cut

sub lookup_location {
    my $self     = shift;
    my $location = shift;
    my %opts     = @_;
  
    my %extras   = $self->_munge('address', $location);
    my $url      = $LOOKUP_API_URL;
    $url        .= '.'.$opts{format} if defined $opts{format};
    
    return $self->_make_restricted_request($url, 'GET', %extras);
}

=head2 within <query> <opt[s]>

Takes a Place ID or a WoE ID and returns a list of users using your 
application who are within the bounding box of that location.

Return the result of the update in either xml or json
depending on C<opts>.

The query can either be a plain string or a hash reference containing
location parameters as described in

    http://fireeagle.yahoo.net/developer/documentation/location#locparams

=cut

sub within {
    my $self     = shift;
    my $location = shift;
    my %opts     = @_;

    my %extras   = $self->_munge('address', $location);
    my $url      = $WITHIN_API_URL;
    $url        .= '.'.$opts{format} if defined $opts{format};

    return $self->_make_restricted_request_general($url, 'GET', %extras);
}


=head2 recent <query> [opt[s]]

Query for users of an Application who have updated their locations recently. 

Return the result of the update in either xml or json
depending on C<opts>.

Query is either a number representing a unix time stamp, to
specify the earliest update to return, or a hash reference containing 
parameters as described in

    http://fireagle.yahoo.net/developer/documentation/querying#recent

=cut

sub recent {
     my $self   = shift;
     my $time   = shift;
     my %opts   = @_;

     my %extras = $self->_munge('time', $time);
     my $url    = $RECENT_API_URL;
     $url      .= '.'.$opts{format} if defined $opts{format};

     return $self->_make_restricted_request_general($url, 'GET', %extras);
}

sub _make_restricted_request_general {
     my $self     = shift;
     my $response = $self->make_general_request(@_);
     return $response->content;
}

sub _make_restricted_request {
    my $self     = shift;
    my $response = $self->make_restricted_request(@_);
    return $response->content;
}

sub _munge {
    my $self  = shift;
    my $key   = shift;
    my $item  = shift || return ();
    my $ref   = ref($item);
    return ( $key => $item ) if !defined $ref or "" eq $ref;
    return %$item            if 'HASH' eq $ref;
    die "Can't understand $key parameter in the form of a $ref ref";  
}

=head1 BUGS

Non known

=head1 DEVELOPERS

The latest code for this module can be found at

    https://svn.unixbeard.net/simon/Net-FireEagle

=head1 AUTHOR

Original code by Yahoo! Brickhouse.

Additional code from Aaron Straup Cope

Rewritten and packaged by Simon Wistow <swistow@sixapart.com>

=head1 COPYRIGHT

Copyright 2008 - Simon Wistow and Yahoo! Brickhouse

Distributed under the same terms as Perl itself.

See L<perlartistic> and L<perlgpl>.

=head1 SEE ALSO

L<Net::OAuth::Simple>

=cut

1;
