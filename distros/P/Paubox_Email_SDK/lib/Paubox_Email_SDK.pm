package Paubox_Email_SDK;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw(
                          getEmailDisposition
                          sendMessage                         
                  );

our $VERSION = '1.2';

use Paubox_Email_SDK::ApiHelper;
use Paubox_Email_SDK::Message;

use JSON;
use Config::General;
use TryCatch;
use String::Util qw(trim);
use MIME::Base64;

my $apiKey ="";
my $apiUser="";
my $baseURL = "https://api.paubox.net:443/v1/";

#
# Default Constructor
#
sub new{    
    my $this = {};    
    try{ 

        my $conf = Config::General  ->  new(
            -ConfigFile => 'config.cfg',
            -InterPolateVars => 1
        );

        my %config = $conf -> getall;
        if(not defined $config{'apiKey'} or 
            $config{'apiKey'} eq ""        
        ) {
            die "apiKey is missing.";
        }

        if(
            not defined $config{'apiUsername'} or 
            $config{'apiUsername'} eq ""             
        ) {
            die "apiUsername is missing.";
        }
        
        $apiKey = $config{'apiKey'};       
        $apiUser = $config{'apiUsername'};

        bless $this;        

    } catch($err) {
         die "Error: " .$err;
    };
    return $this;  
}

#
# Private methods
#

sub _getAuthHeader {
    return  "Token token=" .$apiKey; 
}

sub _returnforceSecureNotificationValue {
    
    my ($forceSecureNotification) = @_; 
    my $forceSecureNotificationValue = "";

    if( !defined($forceSecureNotification) || $forceSecureNotification eq "" ) {        
        return "";
    }
    else {
            $forceSecureNotificationValue = trim ( lc $forceSecureNotification );               
            if ($forceSecureNotificationValue eq "true") {
                return 1;
            } elsif ($forceSecureNotificationValue eq "false") {
                return 0;
            } else {
                return "";
        }
    }          
}

sub _convertMsgObjtoJSONReqObj {
    
    my ($msg) = @_;    
    
    my %reqObject;    
    my $encodedHtmlContent = undef;
    my $forceSecureNotification = $msg -> {'forceSecureNotification'};
    my $forceSecureNotificationValue = _returnforceSecureNotificationValue($forceSecureNotification);       

    if ( defined($msg -> {'html_content'}) and $msg -> {'html_content'} ne "" ) {
        $encodedHtmlContent = trim (encode_base64($msg -> {'html_content'}) );
    }
        
    if($forceSecureNotificationValue eq "" ) {   

        %reqObject = (
        data => {
            message => {
                recipients => $msg -> {'to'},
                cc => $msg -> {'cc'},
                bcc => $msg -> {'bcc'},
                headers => {
                    subject => $msg -> {'subject'},
                    from => $msg -> {'from'},
                    'reply-to' => $msg -> {'replyTo'}
                },
                allowNonTLS => $msg -> {'allowNonTLS'},                
                content => {
                    'text/plain' => $msg -> {'text_content'},
                    'text/html' => $encodedHtmlContent
                },
                attachments => $msg -> {'attachments'},
            },
            
        });
    }
    else {        
        
            %reqObject = (
            data => {
                message => {
                    recipients => $msg -> {'to'},
                    cc => $msg -> {'cc'},
                    bcc => $msg -> {'bcc'},
                    headers => {
                        subject => $msg -> {'subject'},
                        from => $msg -> {'from'},
                        'reply-to' => $msg -> {'replyTo'}
                    },
                    allowNonTLS => $msg -> {'allowNonTLS'},
                    forceSecureNotification => $forceSecureNotificationValue,
                    content => {
                        'text/plain' => $msg -> {'text_content'},
                        'text/html' => $encodedHtmlContent
                    },
                    attachments => $msg -> {'attachments'},
                },                
            });                    
    }
        
    return encode_json (\%reqObject);    
}

#
# Public methods
#


#
# Get Email Disposition
#

sub getEmailDisposition {       
    my ($class,$sourceTrackingId) = @_;    
    my $apiResponseJSON = "";
    try{               
        my $authHeader =  _getAuthHeader() ;
        my $apiUrl = "/message_receipt?sourceTrackingId=" . $sourceTrackingId; 
        my $apiHelper =  Paubox_Email_SDK::ApiHelper -> new();  
        $apiResponseJSON = $apiHelper -> callToAPIByGet($baseURL.$apiUser, $apiUrl, $authHeader);

        # Converting JSON api response to perl
        my $apiResponsePERL = from_json($apiResponseJSON);        

        if (        
            !length $apiResponsePERL -> {'data'} 
            && !length $apiResponsePERL -> {'sourceTrackingId'}  
            && !length $apiResponsePERL -> {'errors'}
        ) 
        {
                die $apiResponseJSON;
        }

        if (
            defined $apiResponsePERL && defined $apiResponsePERL -> {'data'} && defined $apiResponsePERL -> {'data'} -> {'message'}
            && defined $apiResponsePERL -> {'data'} -> {'message'} -> {'message_deliveries'} 
            && (scalar( @{ $apiResponsePERL -> {'data'} -> {'message'} -> {'message_deliveries'} } ) > 0 )         
        ) {      
            foreach my $message_deliveries ( @{ $apiResponsePERL -> {'data'} -> {'message'} -> {'message_deliveries'} } ) {                    

                if( $message_deliveries -> {'status'} -> {'openedStatus'} eq "" ) {  

                    $message_deliveries -> {'status'} -> {'openedStatus'} = "unopened"; 
                    # Converting perl api response back to JSON
                    $apiResponseJSON = to_json($apiResponsePERL);                  
                }
            }               
        }
    } catch($err) {
         die $err;
    };
    
        
    return $apiResponseJSON;
}

#
# Send Email Message
#

sub sendMessage {   
    my ($class,$msgObj) = @_;        
    my $apiResponseJSON = "";
    try{

        my $apiUrl = "/messages";       
        my $reqBody = _convertMsgObjtoJSONReqObj($msgObj);
        my $apiHelper =  Paubox_Email_SDK::ApiHelper -> new(); 
        $apiResponseJSON = $apiHelper -> callToAPIByPost($baseURL.$apiUser, $apiUrl, _getAuthHeader() , $reqBody);                
        # Converting JSON api response to perl
        my $apiResponsePERL = from_json($apiResponseJSON);         

        if (        
            !length $apiResponsePERL -> {'data'} 
            && !length $apiResponsePERL -> {'sourceTrackingId'}  
            && !length $apiResponsePERL -> {'errors'}              
        )  
        {
                die $apiResponseJSON;
        }

    } catch($err) {
         die $err;
    };

    return $apiResponseJSON;    
}

1;
__END__

=head1 NAME

Paubox_Email_SDK - Perl wrapper for the Paubox Transactional Email API (https://www.paubox.com/solutions/email-api).

=head1 SYNOPSIS

    use strict;
    use warnings;
    use Paubox_Email_SDK;

    my $messageObj = new Paubox_Email_SDK::Message(
    'from' => 'sender@domain.com',   
    'to' => ['recipient@example.com'],
    'subject' => 'Testing!',
    'text_content' => 'Hello World!',
    'html_content' => '<html><body><h1>Hello World!</h1></body></html>'  
    );

    my $service = Paubox_Email_SDK -> new();
    my $response = $service -> sendMessage($messageObj);
    print $response;

=head1 DESCRIPTION

This is the official Perl wrapper for the Paubox Transactional Email API (https://www.paubox.com/solutions/email-api). It is currently in alpha development.

The Paubox Transactional Email API allows your application to send secure, HIPAA-compliant email via Paubox and track deliveries and opens. The API wrapper allows you to construct and send messages.


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Paubox Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.


=cut
