package Service::Engine::Alerting::Twilio;

use 5.010;
use strict;
use warnings;
use Data::Dumper;
use Service::Engine;
use Service::Engine::Utility::Twilio::API;

our $Config;
our $Log;
our $Alert;

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
    
    my $self = bless $attributes, $class;
    
    return $self;

}

sub sendSMS {
    my ($self, $args) = @_;  
    
    $Alert = $Service::Engine::Alert;
    
    my $status = 1;
    
    my $msg = $args->{'msg'};
    my $options = $args->{'options'};
    my $handle = $args->{'handle'};
    my $contacts = $options->{'contacts'};
    my $groups = $options->{'groups'};
    my $recipients = $Alert->get_recipients({'groups'=>$groups,'contacts'=>$contacts});
    
    foreach my $recipient (keys %{$recipients}) {
    	if ($recipients->{$recipient}->{'mobile_number'}) {
    	    $self->_send_sms({to=>$recipients->{$recipient}->{'mobile_number'},'msg'=>$msg, 'options'=>$options, 'handle'=>$handle});
    	    $Log->log({'msg'=>"sending an SMS: $msg with options " . Dumper($options),'level'=>3});
    	}
    }
    
    return $status;
}

sub _send_sms {
    
    my ($self, $args) = @_;
    
    my $msg = $args->{'msg'};
    my $to = $args->{'to'};
    my $handle = $args->{'handle'};
    
    if (!$msg || !$to) {
        $Log->log({'msg'=>"Missing required options to send SMS " . Dumper($args),'level'=>2});
        return;
    }
    
    my $handle_config = $Config->get_config('alerting')->{'modules'}->{'Twilio'}->{$handle};
    if (ref($handle_config) ne 'HASH') {
        $Log->log({'msg'=>"Missing $handle config " . Dumper($handle_config),'level'=>2});
        return;
    }
    
    my $AccountSid = $handle_config->{'AccountSid'};
    my $AuthToken = $handle_config->{'AuthToken'};
    my $from = $handle_config->{'from'};
    
    if (!$AccountSid || !$AuthToken || !$from) {
        $Log->log({'msg'=>"Missing required account options to send SMS " . Dumper($handle_config),'level'=>2});
        return;
    }
    
    my $twilio = Service::Engine::Utility::Twilio::API->new('AccountSid' => $AccountSid,
                                                            'AuthToken'  => $AuthToken);

    my $response = $twilio->POST( 'Messages',
                             From => $from,
                             To   => $to,
                             Body  => $msg);

    $Log->log({'msg'=>$response->{content},'level'=>3});

    return;

}

1;