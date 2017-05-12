package Solstice::Controller::Application::REST;

=head1 NAME

Solstice::Controller::Application::REST - The Application controller for the REST 'cgi'. 

=head1 SYNOPSIS

  my $rest = Solstice::Controller::Application::REST->new();
  my $is_valid = $rest->isValidServiceRequest($service_name);
  my $has_access = $rest->hasServiceAccess($service_name, $consumer_private_key);

  my $requires_user_auth = $rest->requiresUserAuth($service_name);
  my $has_user_auth = $rest->hasUserAuth($service_name, $consumer_private_key, $person_id);
  my $response = $rest->getResponseData();

=head1 DESCRIPTION

This process all requests to Solstice REST web services.

=cut

use strict;
use warnings;
use 5.006_000;

use base qw(Solstice::Controller::Application);

use Solstice::Application;
use Solstice::Model::X509;
use Solstice::NamespaceService;
use Solstice::Model::WebserviceConsumer;
use Solstice::Session;
use Digest::SHA1 qw(sha1_hex);


use constant TRUE  => 1;
use constant FALSE => 0;

our $evaled_controllers;

=head2 Export

None by default.

=head2 Methods

=over 4

=item new

=cut

sub handleAuth {
    my $obj = shift;
    my $self = $obj->SUPER::new();
    my $server = Solstice::Server->new();

    #look for the header auth key
    my $auth_key = $server->getHeaderIn('Authorization');
    my $public_id;
    my $signature;
    if($auth_key && $auth_key =~ /^\s*SolAuth\s+(\w+):(\w+)/){
        ($public_id, $signature) = ($1, $2);
    }


    #look for the ssl cert auth
    my $cert        = Solstice::Model::X509->new();


    #pick an auth type to use
    my $consumer;
    if($public_id && $signature){

        #chek if time is close enough
        my $req_date = Solstice::DateTime->new($server->getHeaderIn('Date'));
        my $now = Solstice::DateTime->new(time);
        my $max_diff = 15 * 60;
        unless($req_date->isValid() && abs($now->getTimeApart($req_date)) < $max_diff){
            $server->setStatus(401);
            $self->setErrorString('Time skew too great.');
            return FALSE;
        }

        $consumer = Solstice::Model::WebserviceConsumer->new({public_id => $public_id});

        unless( $self->checkSignature($signature, $consumer->getPrivateKey()) ){
            $server->setStatus(401);
            $self->setErrorString('Signature did not match request.');
            return FALSE;
        }

    }elsif($cert){
        $consumer = Solstice::Model::WebserviceConsumer->new({cert => $cert});
    }


    #if we have a valid consumer, check their access to the requested application
    if($consumer){

        my $app_namespace = Solstice::NamespaceService->new()->getNamespace();

        if( $consumer->hasAppAccessByNamespace($app_namespace) ){

            Solstice::Session->new()->setUser($consumer->getPerson());
            return TRUE;

        }else{
            $server->setStatus(403);
            $self->setErrorString('Access to this web service is denied for the authenticated user.');
        }
    }else{
        $server->setStatus(401);
        $self->setErrorString('No user authentication provided with request.');
    }

    return FALSE;
}


sub runWebservice {
    my $self = shift;
    my $screen = shift;

    my $controller_name = $self->getModel();
    $self->loadModule($controller_name);
    my $controller = $controller_name->new();

    my $server = Solstice::Server->new();
    $server->setContentType('text/xml'); #this can be overridden in the controller's method

    my $output = '';
    if($controller){
        my $method = $server->getMethod();

        if( grep(/^$method$/, qw(GET POST PUT DELETE HEAD OPTIONS)) ){

            if($controller->can($method)){

                my $view = $controller->$method();
                #it's okay to not return a view, no entity body in response
                if($view){
                    $view->paint(\$output);
                }
                $$screen = $output;
                return TRUE;

            }else{

                $self->setErrorString("HTTP method $method not supported by this resource.");
                $server->setStatus(405);
                return FALSE;
            }

        }else{
            $self->setErrorString('HTTP method not present or invalid in request. Must be one of GET, PUT, DELETE, POST, HEAD, OPTIONS');
            $server->setStatus(400);
            return FALSE;
        }

    }else{
        #TODO what situation could cause no controller? Could we be more informative?
        $self->setErrorString('The server could not process your request.');
        $server->setStatus(500);
        return FALSE;
    }
}

sub showError {
    my $self = shift;
    my $screen = shift;

    my $server = Solstice::Server->new();

    #load default error indicatores if needed
    $server->setStatus(500) if ($server->getStatus() == 200);
    my $error_string = $self->getErrorString()|| 'The server could not process your request';

    $$screen = "<error>\n".
    "    <error_status>".$server->getStatus()."</error_status>\n".
    "    <error_string>$error_string</error_string>\n".
    "</error>\n";

}

sub checkSignature {
    my $self = shift;
    my $signature = shift;
    my $private_key = shift;

    my $server = Solstice::Server->new();

    my $method      = $ENV{'REQUEST_METHOD'}             || '';
    my $url         = $ENV{'REQUEST_URI'}                || '';
    my $date        = $server->getHeaderIn('Date')             || '';
    my $content_sha1= $server->getHeaderIn('Content-SHA1')     || '';

    my $body = $server->getRequestBody();

    if($body){
        return FALSE unless sha1_hex($body) eq $content_sha1;
    }

    my $message = "$private_key\n$method\n$url\n$date\n$content_sha1";

    return sha1_hex($message) eq $signature;
}

sub setErrorString {
    my $self = shift;
    $self->{'_error_string'} = shift;
}

sub getErrorString {
    my $self = shift;
    return $self->{'_error_string'};
}


1;

=back


=head1 COPYRIGHT

Copyright 1998-2007 Office of Learning Technologies, University of Washington

Licensed under the Educational Community License, Version 1.0 (the "License");
you may not use this file except in compliance with the License. You may obtain
a copy of the License at: http://www.opensource.org/licenses/ecl1.php

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

=cut
