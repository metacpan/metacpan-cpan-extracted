package Nexmo::SMS::MockLWP;

# ABSTRACT: Module for the Nexmo SMS API!

=head1 DESCRIPTION

This module mocks POST requests. It exists only for the unit tests!

=cut

use LWP::UserAgent;
use HTTP::Response;
use JSON::PP;

use strict;
use warnings;

no warnings 'redefine';

our $VERSION = 0.01;

*LWP::UserAgent::post = sub {
    my ($object,$url,$params) = @_;
    
    my $json = do{ undef $/; <DATA> };
    
    my $coder = JSON::PP->new->ascii->pretty->allow_nonref;
    my $perl  = $coder->decode( $json );
    my $from  = $params->{from};
    
    if ( $url =~ /get-balance/ ) {
        $from = 'get-balance';
        $url  = 'get-balance';
    }
    
    my $subhash   = $perl->{$url}->{$from};
    my $response  = $coder->encode( $subhash );
    
    my $http_response = HTTP::Response->new( 200 );
    $http_response->content( $response );
    
    return $http_response;
};

*LWP::UserAgent::get = sub {
    my ($object,$url,$params) = @_;
    
    my $json = do{ undef $/; <DATA> };
    
    my $coder = JSON::PP->new->ascii->pretty->allow_nonref;
    my $perl  = $coder->decode( $json );
    my $from  = $params->{from};
    
    if ( $url =~ /get-balance/ ) {
        $from = 'get-balance';
        $url  = 'get-balance';
    }
    
    my $subhash   = $perl->{$url}->{$from};
    my $response  = $coder->encode( $subhash );
    
    my $http_response = HTTP::Response->new( 200 );
    $http_response->content( $response );
    
    return $http_response;
};

1;

__DATA__
{
    "http://rest.nexmo.com/sms/json" : {
        "Test01" : {
            "message-count":"1",
            "messages":[
              {
              "status":"0",
              "message-id":"message001",
              "client-ref":"Test001 - Reference",
              "remaining-balance":"20.0",
              "message-price":"0.05",
              "error-text":""
              }
            ]
        },
        "Test03" : {
            "message-count":"1",
            "messages":[
              {
              "status":"4",
              "message-id":"message001",
              "client-ref":"Test001 - Reference",
              "remaining-balance":"20.0",
              "message-price":"0.05",
              "error-text":""
              }
            ]
        },
        "Test04" : {
            "message-count":"1",
            "messages":[
              {
              "status":"0",
              "message-id":"message004",
              "client-ref":"Test004 - Reference",
              "remaining-balance":"20.0",
              "message-price":"0.05",
              "error-text":""
              }
            ]
        },
        "Test05" : {
            "message-count":"1",
            "messages":[
              {
              "status":"0",
              "message-id":"message005",
              "client-ref":"Test005 - Reference",
              "remaining-balance":"20.0",
              "message-price":"0.05",
              "error-text":""
              }
            ]
        }
    },
    "http://test.nexmo.com/sms/json" : {
        "Test02" : {
            "message-count":"2",
            "messages":[
              {
              "status":"0",
              "message-id":"message002",
              "client-ref":"Test002 - Reference",
              "remaining-balance":"10.0",
              "message-price":"0.15",
              "error-text":""
              },
              {
              "status":"0",
              "message-id":"message001",
              "client-ref":"Test001 - Reference",
              "remaining-balance":"20.0",
              "message-price":"0.05",
              "error-text":""
              }
            ]
        }
    },
    "get-balance" : {
        "get-balance" : {
            "value" : 4.15
        }
    }
}
