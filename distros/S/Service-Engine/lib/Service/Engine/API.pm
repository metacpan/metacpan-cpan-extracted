package Service::Engine::API;

use 5.010;
use strict;
use warnings;
use Carp;
use Service::Engine;
use Data::Dumper;
use Module::Runtime qw(require_module);
use Service::Engine::Admin::Server;
use threads;
use threads::shared;

our $Config;
our $Log;
our $EngineName;
our $Commands = {};
our $CommandList = '';
our $Server;
our $Threads;
our $Engine;
our $Health;

share($Health);
share($Commands);
share($CommandList);

# load desired classes 
# Service::Engine::API:*

sub new {
    
    my ($class,$options) = @_;
    
    # set some defaults
    my $attributes = {'methods'=>{}};
    
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
    $Threads = $Service::Engine::Threads;
    $Health = $Service::Engine::Health;
    $Engine = $Service::Engine::Engine;
    
    my $self = bless $attributes, $class;
        
    # create our admin methods
    # these will be autoloaded from Service::Engine like this my $method = $Admin->methodname();
    # this works by adding the connection methods to $attributes->{'methods'}->{methodname}
    # save the method label to $Methods->{$label} = $type;
    
    if (ref($Config->get_config('admin')) eq 'HASH') {
    
        if ($Config->get_config('admin')->{'enabled'}) {
            foreach my $service (keys $Config->get_config('admin')->{'modules'}) {
                
                my $service_conf = $Config->get_config('admin')->{'modules'}->{$service};
                
                $Log->log({msg=>Dumper($service_conf),level=>3});
                
                if ($service_conf->{'enabled'}) {
                    $Log->log({msg=>"loading $service",level=>2});
                    my $package = 'Service::Engine::Admin::' . ucfirst lc $service;
                
                    if ($service_conf->{'module_name'}) {
                        $package = $EngineName . '::Modules::' . $service_conf->{'module_name'};
                    }
                    my $res = eval { require_module($package) };
                    if ($@) {
                        $Log->log({msg=>"error loading $service: $@",level=>1});
                    } else {
                        my $obj = $package->new($self,$service_conf->{'options'});
                    }
                }
                
            }
            
            # set up commands
            $self->add_command({'module'=>$Threads, 'method'=>'add_thread', 'label'=>'AddThread'});
            $self->add_command({'module'=>$self, 'method'=>'stop_engine', 'label'=>'StopEngine'});
            $self->add_command({'module'=>$Engine, 'method'=>'start_selector', 'label'=>'StartEngine'});

        }
        
    }
    
    return $self;

}

sub start_api_server {
    
    my $self = shift;
        
    if ($Config->get_config('admin')->{'enabled'}) {
        my $host_ip = $Config->get_config('api')->{'host_ip'};
        my $host_port = $Config->get_config('api')->{'host_port'};    
        $host_ip ||= '127.0.0.1';
        $host_port ||= '42180';
        my $key_file = $Config->get_config('api')->{'ssl'}->{'SSL_key_file'};
        my $cert_file = $Config->get_config('api')->{'ssl'}->{'SSL_cert_file'};
    
        $Server = Service::Engine::API::Server->new(
                                                        'host' => $host_ip, 
                                                        'port' => $host_port, 
                                                        'server_type' => ['Net::Server::Multiplex'],
                                                        'SSL_key_file'  => $key_file,
                                                        'SSL_cert_file' => $cert_file,
                                                    );
        $Server->run;
    }
    
}

sub expand {
    
    my $self = shift;
    my $stub = shift;
    
    my $commands = $CommandList;
    my @commands = split /\n/, $commands;
    
    foreach my $command (@commands) {
    	return "!$command" unless $command !~ /^$stub/i;
    }
    
    return $stub;
    
}

sub command_list {
    my $self = shift;
    return $CommandList;
}

sub add_command {
    my ($self,$command) = @_;
    
    if (ref($command) ne 'HASH') {
        $Log->log({msg=>"invalid command format - must be a hash:" . Dumper($command),level=>2});
        return;
    }
    
    if (!$command->{'module'} || !$command->{'method'} || !$command->{'label'}) {
        $Log->log({msg=>"invalid command format - missing module, method or label:" . Dumper($command),level=>2});
        return;
    }
    
    warn($command->{'label'} . ':' . Dumper($command->{'module'}));
    
    $Commands->{$command->{'label'}} = shared_clone({'module'=>$command->{'module'}, 'method'=>$command->{'method'}});
    my @commands = split /\n/, $CommandList;
    push @commands, $command->{'label'};
    $CommandList = join "\n", sort @commands;
    
    return;
}

sub stop_engine {
    # we do this here because it blocks while it waits; that would be bad in the Engine
    my ($self,$fh) = @_;
   
    $fh->write("shutting down\n") unless !$fh;
    my $stop = $Engine->stop_selector($fh);
    $fh->write("waiting for the backlog to finish processing\n") unless !$fh;
    
    # wait for it
###>>>TO DO - we need to do this in a separate thread so it doesn't block admin entirely
    while ($Threads->get_queue_count()){};
    
    $fh->write("All done.") unless !$fh;
    
}

our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    # Remove qualifier from original method name...
    my $called = $AUTOLOAD =~ s/.*:://r;
    # Is there an attribute of that name?
    # check for an expansion
    $called = $self->expand($called);
    
    if ($called =~ /^\!/) { # this is a command
        $called =~ s/^\!//;
        return $Commands->{$called};
    } else {
        print "Hmm. $called? Available options are: \n$CommandList\n> "
          unless exists $self->{'methods'}->{$called};
        # If so, return it...
        return $self->{'methods'}->{$called};
    }

}

1;