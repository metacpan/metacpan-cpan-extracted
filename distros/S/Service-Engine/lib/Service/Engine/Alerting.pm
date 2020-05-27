package Service::Engine::Alerting;

use 5.010;
use strict;
use warnings;
use Carp;
use Service::Engine;
use Data::Dumper;
use Module::Runtime qw(require_module);

our $Config;
our $Log;
our $AlertingConfig = {};
our $Modules = {};
our $EngineName;
our $Contacts = {};
our $Groups = {};

# load desired classes 
# Service::Engine::Alerting:*

sub new {
    
    my ($class,$options) = @_;
    
    # set some defaults
    my $attributes = {'modules'=>{}};
    
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
    
    # create our alerting handles
    #$Modules->{$handle}->$module_method
    $Log->log({'msg'=>"loading Alerting",'level'=>1});

    if (ref($Config->get_config('alerting')) eq 'HASH') {
        $AlertingConfig = $Config->get_config('alerting');
        
        if ($AlertingConfig->{'enabled'}) {
             $Log->log({'msg'=>"Alerting enabled",'level'=>2});
            foreach my $service (keys $AlertingConfig->{'modules'}) {
                my $module_config = $AlertingConfig->{'modules'}->{$service};
                if (ref($module_config) eq 'HASH' && keys %{$module_config}) {
                    foreach my $handle (keys %{$module_config}) { 
                        next unless keys %{$module_config->{$handle}};
                        next unless $module_config->{$handle}->{'enabled'};
                        $Log->log({'msg'=>"loading $handle for $service",'level'=>2});
                        my $package = 'Service::Engine::Alerting::' . ucfirst lc $service;
                        if ($module_config->{$handle}->{'module_name'}) {
                            $package = $EngineName . '::Modules::' . $module_config->{$handle}->{'module_name'};
                        }
                        my $res = eval { require_module($package) };
                        if ($@) {
                            $Log->log({'msg'=>"error loading $handle for $service: $@",'level'=>1});
                        } else {
                            my $obj = $package->new($module_config->{$handle}); # passes in the config
                            $Modules->{$handle} = $attributes->{'modules'}->{$handle} = $obj;
                        }
                    
                    }
                }
            }

        }
    }
        
    my $contact_config = $Config->get_config('contacts');
    if (ref($contact_config) eq 'HASH'){
        $Contacts = $contact_config;
    } else {
        $Log->log({'msg'=>"error loading contacts",'level'=>2});
    }
    
    my $groups_config = $Config->get_config('groups');
    if (ref($groups_config) eq 'HASH'){
        $Groups = $groups_config;
    } else {
        $Log->log({'msg'=>"error loading groups",'level'=>2});
    }
    
    my $self = bless $attributes, $class;
    
    return $self;

}

sub send {
    
    my ($self,$args) = @_;
    
    return 0 unless $AlertingConfig->{'enabled'};
    
    my $module = $args->{'module'};
    my $handle = $args->{'handle'};
    my $msg = $args->{'msg'};
    my $options = $args->{'options'};
    my $module_method = $AlertingConfig->{'modules'}->{$module}->{$handle}->{'method'};
        
    if (ref($options) ne 'HASH') {
        $Log->log({'msg'=>"error loading options",'level'=>2});
        return 0;
    }
    
    if (!$module_method) {
        $Log->log({'msg'=>"error: missing module method",'level'=>2});
        return 0;
    }
    
    $Log->log({'msg'=>"sending a $module:$module_method alert",'level'=>3});
    
    if (!$Modules->{$handle}) {
        $Log->log({'msg'=>"error: missing $module:$handle",'level'=>2});
        return 0;
    }
    
    # send out an alert
    $Modules->{$handle}->$module_method({'msg'=>$msg, 'handle'=>$handle, 'options'=>$options});
    
    return 1;
}

sub contacts { 
    my ($self) = @_;
    return $Contacts;
}

sub groups { 
    my ($self) = @_;
    return $Groups;
}

sub get_recipients { 
    my ($self,$args) = @_;
    
    my $contacts = {};
    my $contact_names = $args->{'contacts'};
    if (ref($contact_names) eq 'ARRAY') {
        foreach my $contact_name (@{$contact_names}) {
        
            my $contact = $Contacts->{$contact_name};
            if (ref($contact) eq 'HASH') {
                $contacts->{$contact_name} = $contact;
            } else {
                $Log->log({'msg'=>"$contact_name not found",'level'=>2});
            }
        
        }
    }
    
    my $group_members = $self->get_group_contacts($args->{'groups'});
    
    my %merged = (%$contacts,%$group_members);
    $contacts = \%merged;
    
    return $contacts;
}

sub get_group_contacts {

    my ($self,$groups) = @_;
    
    my $contacts = {};
    
    if (ref($groups) eq 'ARRAY') {
        foreach my $group (@{$groups}) {
        	# get the group members
        	my $group_members = $Groups->{$group};
        	if (ref($group_members) eq 'ARRAY') {
        	    foreach my $contact_name (@{$group_members}) {
        	    	my $contact = $Contacts->{$contact_name};
        	    	if (ref($contact) eq 'HASH') {
        	    	    $contacts->{$contact_name} = $contact;
        	    	} else {
        	    	    $Log->log({'msg'=>"$contact_name not found",'level'=>2});
        	    	}
        	    }
        	    
        	}
        }
        
    }
    
    return $contacts;
}

1;