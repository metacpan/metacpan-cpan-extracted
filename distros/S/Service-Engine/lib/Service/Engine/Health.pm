package Service::Engine::Health;

use 5.010;
use strict;
use warnings;
use Data::Dumper;
use Module::Runtime qw(require_module);

use Service::Engine;
use threads;
use threads::shared;
use JSON;

our $Config;
our $Log;
our $Data;
our $EngineName;
our $EngineInstance;
our $Threads;
our $Checks = {};
our $CheckList = [];
our $CheckCounts = {};
our $Admin;
our $Alert;
our $check_prefix;
our $Thresholds;
our $Memcached;

share($Threads);
share($Checks);
share($CheckList);
share($CheckCounts);
share($Admin);
share($Log);

sub new {
    
    my ($class,$options) = @_;
    
    # set some defaults
    my $attributes = {};
    
    # load options
    if (ref($options) eq 'HASH') {
        foreach my $option (keys %{$options}) {
            $attributes->{$option} = $options->{$option};
        }
    }
    
    # pull in some Service::Engine globals
    $Config = $Service::Engine::Config;
    $EngineName = $Service::Engine::EngineName;
    $EngineInstance = $Service::Engine::EngineInstance;
    $Threads = $Service::Engine::Threads;
    $Log = $Service::Engine::Log;
    $Admin = $Service::Engine::Admin;
    $Alert = $Service::Engine::Alert;
    
    $check_prefix = $EngineName . ':' . $EngineInstance . ':healthcheckID:';
    
    my $self = bless $attributes, $class;
       
    # create our health checks
    
    if (ref($Config->get_config('health')) eq 'HASH') {
    
        my @options = ();
        foreach my $service (keys $Config->get_config('health')->{'modules'}) {
                    
            my $service_conf = $Config->get_config('health')->{'modules'}->{$service};
            
            $Log->log({'msg'=>Dumper($service_conf),'level'=>3});
            
            if ($service_conf->{'enabled'}) {
                $Log->log({'msg'=>"loading $service",'level'=>2});
                my $package = 'Service::Engine::Health::' . ucfirst lc $service;
            
                if ($service_conf->{'module_name'}) {
                    $package = $EngineName . '::Modules::' . $service_conf->{'module_name'};
                }
                my $res = eval { require_module($package) };
                if ($@) {
                    $Log->log({'msg'=>"error loading $service: $@",'level'=>1});
                } else {
                    my $obj = $package->new($Admin);
                    $Checks->{$service} = shared_clone($obj);
                    push @options, $service;
                }
            }
            
        }
        
        $CheckList = \@options;
                        
    }
    
    if ($Admin) {
        $Admin->add_command({'module'=>$self, 'method'=>'overview', 'label'=>'Overview'});
        $Admin->add_command({'module'=>$self, 'method'=>'api_overview', 'label'=>'API Overview'});
    }
    
    return $self;

}

sub start { # intended to run in its own thread in a loop
    
    my ($self) = @_;
    
    $Log->log({'msg'=>"starting Health Monitor",'level'=>1});
    
    my $timeout = $Config->get_config('health')->{'frequency'};
    $Thresholds = $Config->get_config('health')->{'alerting'};
    my $health_alerts_enabled = $Config->get_config('health')->{'health_alerts_enabled'};
    
    my $memcached_config = $Config->get_config('health')->{'memcached'};
    if (ref($memcached_config) eq 'HASH') {
        if (ref($memcached_config->{'options'}) eq 'HASH') {
            if ($memcached_config->{'options'}->{'handle'} && $memcached_config->{'options'}->{'enabled'}) {
                $Memcached = $Data->$memcached_config->{'options'}->{'handle'};
            }
        }
    }
    
    while (1) {
        
        $Log->log({msg=>"checking health",level=>3});
        
        warn(Dumper($Checks));
        
        foreach my $check (keys %{$Checks}) {
        	$Log->log({msg=>"checking $check",level=>3});
        	my $status = $Checks->{$check}->check();
        	if ($health_alerts_enabled) {
        	    $self->_process_status($check,$status);
        	}
        }
                
        sleep($timeout);  
    }
    
}

sub _process_status {
    
    my ($self, $check, $status) = @_;
    
    $Log->log({'msg'=>"$check status:" . Dumper($status),'level'=>3});
    
    if (ref($status) ne 'HASH') {
        $Log->log({'msg'=>"$check check status was not an object" . Dumper($status),'level'=>2});
        return;
    }
    
    # check the healthcheckID counter
    my $check_count = $self->get_check_count($check);
    
    $Log->log({'msg'=>"$check check is in error" . Dumper($status),'level'=>2}) unless ($status->{'state'} eq 'ok');
    
    # we go through this regardless of state to process info objects for logging

    my $condition_config = $Thresholds->{$status->{'condition'}};
    
    if (ref($condition_config) ne 'HASH') {
        $Log->log({'msg'=>"$check condition " . $status->{'condition'} . " is undefined",'level'=>2});
        return;
    }
    
    foreach my $alerting_module (keys %{$condition_config->{'modules'}}) {
        my $alerting_module_config = $condition_config->{'modules'}->{$alerting_module};
        warn("$alerting_module " . Dumper($alerting_module_config));
        if (ref($alerting_module_config) ne 'HASH') {
            $Log->log({'msg'=>"$check alerting module $alerting_module is undefined",'level'=>2});
            next;
        }
        foreach my $handle (keys %{$alerting_module_config}) {
            my $handle_config = $alerting_module_config->{$handle};
            if (ref($handle_config) ne 'HASH') {
                $Log->log({'msg'=>"$check alerting method $alerting_module : $handle is undefined",'level'=>2});
                next;
            }
            if (!$handle_config->{'enabled'}) {
                next;
            }
            
            my $threshold = $handle_config->{'every'};
            $threshold ||= 0;
            # we finally have a valid alerting method
            # lets check our threshold
            my $modulus = 0;
            if ($threshold) {
                $modulus = $check_count % $threshold;
                warn("$alerting_module:$handle modulus: $modulus threshold: $threshold count: $check_count");
            }
            if (!$modulus || !$threshold || !$check_count) {
                $Alert->send({'msg'=>$status->{'msg'},'module'=>$alerting_module, 'handle'=>$handle, 'options'=>$handle_config});
            }

        }
        
    }
    
    # increment the healthcheckID counter
    $check_count++;
    $self->set_check_count($check, $check_count);

     if ($status->{'state'} eq 'ok') {
        # reset the healthcheckID counter
        $self->set_check_count($check, 0) unless !$check_count;
    }
    
    return '';
}

sub get_check_count {

    my ($self,$check) = @_;
    
    my $count = 0;
    
    my $key = $check_prefix . $check;
    
    if ($Memcached) {
        $count = $Memcached->get($key);
    } else {
        $count = $CheckCounts->{$key} ||= 0;
    }
    
    warn("COUNT[$key]: $count\n");
    
    return $count;

}

sub set_check_count {

    my ($self,$check,$count) = @_;
    
    my $key = $check_prefix . $check;
    
    if ($Memcached) {
        $Memcached->set($key,$count);
    } else {
        $CheckCounts->{$key} = $count;
    }
        
    return '';

}

sub overview { # this method is invoked from the admin prompt

    my ($self, $fh, $for_api) = @_;
    
    my $overview = {};
    my @overviews = ();
    
    foreach my $check (keys %{$Checks}) {
        $Log->log({msg=>"checking $check",level=>3});
        my $status = $Checks->{$check}->check();
        $overview->{$check} = $status->{'data'};
        push @overviews, $status->{'msg'};
    }
    
    my $overview_txt = join "\n", @overviews;
    
    my $backlog = $Threads->get_queue_count();
    
    if ($fh) {
        $fh->write($overview_txt);
    }
    
    if ($for_api) {
        return $overview;
    }
    
    
}

sub api_overview {
    
    my ($self, $fh) = @_;
    
    my $data = $self->overview(undef,1);
    my $json = JSON->new->allow_nonref;
    my $json_string = eval{$json->encode( $data )};
    $Log->log({'msg'=>"$@",'level'=>2}) if $@;
    if ($fh) {
        $fh->write($json_string);
    } else {
        return $json_string;
    }
    
}



1;