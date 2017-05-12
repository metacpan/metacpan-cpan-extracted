package OpenTok::API;

use 5.006;
use strict;
use warnings;

use Time::HiRes;
use MIME::Base64;
use Digest::HMAC_SHA1 qw(hmac_sha1_hex);

use LWP;
use XML::XPath;

use OpenTok::API::Session;
use OpenTok::API::Exceptions;

=head1 NAME

OpenTok::API - Perl SDK for OpenTok
http://www.tokbox.com/

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';
our $API_VERSION = 'tbpl-v0.03.2013-07-10';
our %API_SERVER = ( 
    "development" => "https://staging.tokbox.com/hl",
    "production"  => "https://api.opentok.com/hl"
);
our %RoleConstants = (
    "SUBSCRIBER" => "subscriber",
    "PUBLISHER"  => "publisher",
    "MODERATOR"  => "moderator",
);

=head1 SYNOPSIS

1. Generate Token

    use OpenTok::API;
    
    # Get your own API-keys from http://www.tokbox.com/opentok
    my $ot = OpenTok::API->new(
        'api_key'    => $api_key, 
        'api_secret' => $api_secret,
        'mode'       => "development"|"production",
    );
    
2. Create new session

    my $session_id = $ot->create_session( 
        location => '', 
        'p2p.preference' => "enabled"|"disabled" 
    )->getSessionId();
    
3. Generate a new token for session
    
    my $token = $ot->generate_token(
        session_id => $session_id, 
        role => "publisher"|"subscriber"|"moderator" 
    );

4. Now insert your $api_key, $session_id, and $token into your template using your favourite templating engine

    # TT example 

    # In server side code
    my $tt = Template->new(...});
    my $vars = { api_key => $api_key, session_id => $session_id, token => $token };
    $tt->process($template, $vars) || die $tt->error(), "\n";

    # In HTML (javascript part)
    var apiKey    = "[% api_key %]";
    var sessionId = "[% session_id %]";
    var token     = "[% token %]";
    ...
    var session = TB.initSession(sessionId);
    session.addEventListener("sessionConnected", sessionConnectedHandler);
    session.addEventListener("streamCreated", streamCreatedHandler);
    session.connect(apiKey,token);


=head1 SUBROUTINES/METHODS

=head2 new

Creates and returns a new OpenTok::API object

    my $ot = OpenTok::API->new(
        'api_key'    => $api_key, 
        'api_secret' => $api_secret,
        'mode'       => "development"|"production",
    );

=over 4

=item * C<< api_key => string >>

Sets your TokBox API Partner Key

=item * C<< api_secret => string >>

Sets your TokBox API Partner Secret 

=item * C<< mode => "development|"production" >>

Set it to "production" when you launch your app in production. Default is "development".

=back

=cut

sub new {
    my ($class, %args) = @_;
    my $self = {
        api_key => exists $args{api_key} ? $args{api_key} : '_api_key_',
        api_secret => exists $args{api_secret} ? $args{api_secret} : '_api_secret_',
        api_mode => exists $args{mode} ? $args{mode} : 'development',
    };
    
    bless $self, $class;
    
    return $self;
}

=head2 generate_token

Generates a token for specific session.

    my $token = $ot->generate_token(
        session_id => $session_id, 
        role => "publisher"|"subscriber"|"moderator",
        expire_time => (time()+24*3600),
    );

=over 4

=item * C<< session_id => string >>

If session_id is not blank, this token can only join the call with the specified session_id.

=item * C<< role => "subscriber"|"publisher"|"moderator" >>

One of the roles. Default is publisher, look in the documentation to learn more about roles.
http://www.tokbox.com/opentok/api/tools/as3/documentation/overview/token_creation.html

=item * C<< expire_time => int >>

Optional. The time when the token will expire, defined as an integer value for a Unix timestamp (in seconds).
If you do not specify this value, tokens expire in 24 hours after being created.
The expiration_time value, if specified, must be within 30 days of the creation time.

=back

=cut

sub generate_token {
    my $self = shift;
    my $create_time = time();
    my %arg = (
        session_id => '',
        role => $RoleConstants{PUBLISHER},
        expire_time => ($create_time +24*3600),
        @_,        
    );
    my $nonce = rand();
    my $query_string = "role=" . $arg{role} .
                       "&session_id=" . $arg{session_id} .
                       "&create_time=" . $create_time .
                       "&nonce=" . $nonce .
                       "&expire_time=" . $arg{expire_time} .
                       "&connection_data=";
    my $signature = hmac_sha1_hex($query_string, $self->{api_secret});
    return "T1==" . encode_base64("partner_id=".$self->{api_key}."&sdk_version=$API_VERSION&sig=$signature:$query_string",'');
     
}

=head2 create_session

Creates and returns OpenTok::API::Session object

    my $session_id = $ot->create_session( 
        location => '', 
        'p2p.preference' => "enabled"|"disabled" 
    )->getSessionId();

=over 4

=item * C<< location => string >>

An IP address that TokBox will use to situate the session in its global network. 
In general, you should not specify a location hint; if no location hint is specified,
the session uses a media server based on the location of the first client connecting to the session. 
Specify a location hint only if you know the general geographic region (and a representative IP address) 
for the session and you think the first client connecting may not be in that region.

=item * C<<  'p2p.preference' => 'enabled' >>

The properties option includes any following key value pairs. Currently only the following property exists:

p2p.preference (String) . Whether the session's streams will be transmitted directly between peers. You can set the following possible values:

"disabled" (the default) . The session's streams will all be relayed using the OpenTok servers. More than two clients can connect to the session.

"enabled" . The session will attempt to transmit streams directly between clients. If peer-to-peer streaming fails (either when streams are 
initially published or during the course of a session), the session falls back to using the OpenTok servers for relaying streams. 
(Peer-to-peer streaming uses UDP, which may be blocked by a firewall.) For a session created with peer-to-peer streaming enabled, 
only two clients can connect to the session at a time. If an additional client attempts to connect, 
the TB object on the client dispatches an exception event.
By removing the server, peer-to-peer streaming decreases latency and improves quality.

Note that the properties object previously included settings for multiplexing and server-side echo suppression. 
However, these features were deleted in OpenTok v0.91.48. (Server-side echo suppression was replaced with the 
acoustic echo cancellation feature added in OpenTok v0.91.18.)

=back

=cut

sub create_session {
    my $self = shift;
    my %arg = (
        location => '',
        api_key => $self->{api_key},
        @_,
    );
    my $session_raw = $self->_do_request("/session/create", %arg);
    my $session_xml;
    
    eval {
       $session_xml = XML::XPath->new( xml => $session_raw ) or OpenTok::API::Exception->throw( error => "Failed to create session: Invalid response from server: $!" );
    };    
    
    return if (Exception::Class->caught('OpenTok::API::Exception'));
    
    if($session_xml->exists('/Errors')) {
        my $err_msg = $session_xml->find('//@message');
        $err_msg = 'Unknown error' unless $err_msg;
        
        OpenTok::API::Exception::Auth->throw(error => "Error " . $session_xml->find('//@code') ." ". $session_xml->find('local-name(//error/*[1])') . ": " . $err_msg );
        
        return;       
    }
    
    return OpenTok::API::Session->new( map {  $_->getName => $_->string_value } $session_xml->find('//Session/*')->get_nodelist);       
    
}

# private methods

sub _do_request {
    my $self = shift;
    my $cmd = shift;
    my %arg = (
      @_,       
    );
    
    my $url = $API_SERVER{$self->{api_mode}}.$cmd;
    
    my $data =  join '&', map { "$_=".$self->_urlencode($arg{$_}) } keys %arg;
    
    my $ua = LWP::UserAgent->new;
    #$ua->agent("$0/0.1 " . $ua->agent);
    
    my $request = HTTP::Request->new(POST => $url);
    $request->header('X-TB-PARTNER-AUTH' => $self->{api_key}.':'.$self->{api_secret});
    $request->content_type('application/x-www-form-urlencoded');
    $request->content($data);
    
    my $result = $ua->request($request);

    if ($result->is_success) {
          return $result->content;
    }
    else {
       OpenTok::API::Exception::Auth->throw( error => "Request error: ".$result->status_line );
       return;
    }

}

sub _urlencode {
    my ($self, $data) = @_;

    $data =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;
    return $data;    
}

=head1 AUTHOR

This version: Dr James Freeman, C<< <james at gp2u.com.au> >>
Original version: Maxim Nikolenko, C<< <root at zbsd.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-opentok-api at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=OpenTok::API>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc OpenTok::API

You can also look for information at:

http://www.tokbox.com/opentok

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=OpenTok::API>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/OpenTok-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/OpenTok-API>

=item * Search CPAN

L<http://search.cpan.org/dist/OpenTok-API/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Maxim Nikolenko.

This module is released under the following license: BSD


=cut

1; # End of OpenTok
