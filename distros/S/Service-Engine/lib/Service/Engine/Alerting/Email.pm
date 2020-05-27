package Service::Engine::Alerting::Email;

use 5.010;
use strict;
use warnings;
use Data::Dumper;
use Service::Engine;
use Service::Engine::Utility::Email;

our $Config;
our $Log;
our $Alert;
our $EngineName;
our $EngineInstance;

sub new {
    
    my ($class,$options) = @_;
        
    # set some defaults
    my $attributes = {'method'=>''};
    
    # load options
    if (ref($options) eq 'HASH') {
        foreach my $option (keys %{$options}) {
            $attributes->{$option} = $options->{$option};
        }
    }
    
    # pull in some Service::Engine globals
    $Config = $Service::Engine::Config;
    $Log = $Service::Engine::Log;
    $EngineName = $Service::Engine::EngineName;
    $EngineInstance = $Service::Engine::EngineInstance;
    
    my $self = bless $attributes, $class;
    
    return $self;

}

sub sendEmail {
    my ($self, $args) = @_;  
    
    $Alert = $Service::Engine::Alert;
    
    my $status = 1;
    
    my $msg = $args->{'msg'};
    my $options = $args->{'options'};
    my $handle = $args->{'handle'};
    my $contacts = $options->{'contacts'};
    my $groups = $options->{'groups'};
    my $recipients = $Alert->get_recipients({'groups'=>$groups,'contacts'=>$contacts});   
    
    my $handle_config = $Config->get_config('alerting')->{'modules'}->{'Email'}->{$handle};
    
    if (ref($handle_config) ne 'HASH') {
        $Log->log({'msg'=>"Missing $handle config " . Dumper($handle_config),'level'=>2});
        return 0;
    }
    
    $args->{'from'} = $handle_config->{'from'};
    $args->{'smtp_ip'} = $handle_config->{'smtp_ip'};
    $args->{'smtp_port'} = $handle_config->{'smtp_port'};
    $args->{'subject'} = "$EngineName" . "[$EngineInstance] ALERT: $msg";
    $args->{'force_text'} = 1;
    
    if (!$args->{'from'}) {
        $Log->log({'msg'=>"Missing required account options to send Email " . Dumper($handle_config),'level'=>2});
        return 0;
    }
    
    foreach my $recipient (keys %{$recipients}) {
    	if ($recipients->{$recipient}->{'email'}) {
    	    $args->{'to'} = $recipients->{$recipient}->{'email'};
    	    my $status = $self->_send_email($args);
    	    $Log->log({'msg'=>"could not send mail to $args->{'to'}",'level'=>2}) unless $status;
    	}
    }
    
    return $status;
}

sub _send_email {
    
    my ($self, $args) = @_;
    
    my $msg = $args->{'msg'};
    my $to = $args->{'to'};
    
    if (!$msg || !$to) {
        $Log->log({'msg'=>"Missing required options to send email " . Dumper($args),'level'=>2});
        return 0;
    }
    
    # send our email here
    my $smtp = Service::Engine::Utility::Email->new();

    my $response = $smtp->send($args);

    return $response;

}

1;