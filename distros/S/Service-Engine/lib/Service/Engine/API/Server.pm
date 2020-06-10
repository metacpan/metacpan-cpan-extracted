package Service::Engine::API::Server;

use 5.010;
use strict;
use warnings;
use Carp;
use Service::Engine;
use Service::Engine::Admin;
use base qw(Net::Server::HTTP);
use Data::Dumper;
use JSON;
use CGI;

sub process_http_request {

    my $self = shift;
    
    my $json = JSON->new->allow_nonref;
    
    my $content = '';
    my $form = {};
    my $q = CGI->new; 
    $form->{$_} = $q->param($_) for $q->param;
    
    # pull in some Service::Engine globals
    $self->{'Config'} = $Service::Engine::Config;
    $self->{'Log'} = $Service::Engine::Log;
    $self->{'Admin'} = $Service::Engine::Admin;
    $self->{'EngineName'} = $Service::Engine::EngineName;
    $self->{'Health'} = $Service::Engine::Health;
    $self->{'Threads'} = $Service::Engine::Threads;
    
    my $api_password = $self->{'Config'}->get_config('api')->{'password'};
    if ($api_password && ($form->{'password'} ne $api_password)) {
        $content = eval{$json->encode( {'error'=>"access denied"} )};
    } else {
        my $allowed_resources = $self->{'Config'}->get_config('api')->{'allowed_resources'};
        my $path = $ENV{'REQUEST_URI'};
        
        # strip off query 
        if ($path =~ /\?/) {
        	$path =~ s/(.*)\?.*/$1/;
        }
        
        my (undef,$module,$method,$params) = split /\//, $path;
    	warn("trying $module: $method : $params"); 
    	 
        $content = eval{$json->encode( {'error'=>"unknown resource $path"} )};
    
        if ($module && $method && $allowed_resources->{$module}) {
            if ($allowed_resources->{$module}->{$method}) {
               warn("trying $module: $method"); 
               my $eval_content = eval{$self->{$module}->$method()};
               if ($eval_content) {
               		$content = $eval_content;
               }
            }
        }
    }
     
    print "Content-type: application/json\n\n";
    print $content;

}

1;