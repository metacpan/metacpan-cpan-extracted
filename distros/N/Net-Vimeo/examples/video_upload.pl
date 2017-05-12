use strict;
use warnings;

use Net::Vimeo;
use LWP::UserAgent;
use HTTP::Request::Common;
use JSON;

my $vimeo_oauth = Net::Vimeo->new(
    consumer_key          => $ENV{VIMEO_CONSUMER_KEY},
    consumer_secret       => $ENV{VIMEO_CONSUMER_SECRET},
);

my $auth_url = $vimeo_oauth->get_authorization_url( permission => 'write', callback => '<your_callbackurl>' );

print "\n1. Authorize the Vimeo App at: $auth_url\n2. To complete the authorization please enter the given verifier: ";

my $oauth_verifier = <STDIN>;
chomp $oauth_verifier;
print "\n";

$vimeo_oauth->get_access_token( { verifier => $oauth_verifier } );

# Vimeo upload

# # Get ticket:
# #vimeo.videos.upload.getTicket

# # Make an api request 
my $upload_params = {
    method          => 'vimeo.videos.upload.getTicket',
    upload_method   => 'POST',
    format          => 'json',
    chunk_id        => 1,
};

my $resp_content = $vimeo_oauth->make_api_request( 'GET', $upload_params);
my $ticket_response = decode_json($resp_content->content);

printf( "EndPoint: %s \n", $ticket_response->{ticket}->{endpoint} );
printf( "Ticket id: %s \n", $ticket_response->{ticket}->{id} );

# Upload: 
my $ua = LWP::UserAgent->new();
my $video_path = '<add_here_the_video_path>'; 

my $upload_res = $ua->request( POST $ticket_response->{ticket}->{endpoint},  Content_Type => 'form-data', Content => [ ticket_id => $ticket_response->{ticket}->{id}, file => $video_path, chunk_id => 1 ] );

printf( 'Upload response: %s\n', $upload_res->content);

my $ticketparams = {
    method          => 'vimeo.videos.upload.complete',
    ticket_id       => $ticket_response->{ticket}->{id},
    filename        => $video_path,
    format          => 'json',
};

my $comp_content = $vimeo_oauth->make_api_request( 'GET', $ticketparams);




