package Service::Engine::Health::Threads;

use 5.010;
use strict;
use warnings;
use Data::Dumper;
use JSON;

use Service::Engine;

our $Config;
our $Log;
our $Threads;
our $EngineName;
our $EngineInstance;

# are enough threads running?

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
    $Threads = $Service::Engine::Threads;
    $EngineName = $Service::Engine::EngineName;
    $EngineInstance = $Service::Engine::EngineInstance;
    
    # set some defaults
    
    my $self = bless $attributes, $class;
    
    return $self;

}

# a check returns a status object
sub check {
    my ($self) = @_;
    
    # do our test and set state
    my $options = $Config->get_config('health')->{'modules'}->{'Threads'}->{'options'};
    if (ref($options) ne 'HASH') {
        $Log->log({'msg'=>"Threads options not found",'level'=>2});
        return {};
    }
    
    my $critical = $options->{'critical'};
    my $warning = $options->{'warning'};
    my $thread_count = $Threads->get_thread_count();
    
    my $condition = ($thread_count <= $critical) ? 'critical' : ($thread_count < $warning) ? 'warning' : 'info';
    my $state = ($condition eq 'info') ? 'ok' : 'error'; 
    my $msg = uc($condition) . ": $EngineName:$EngineInstance thread count is $thread_count";
    my $data = {'thread_count'=>$thread_count, 'condition'=>$condition, 'state'=>$state, 'msg'=>$msg, 'time'=>time()};
    
    my $status = {
                    'state'=>$state, # ok | error
                    'condition'=>$condition, # info|warning|critical
                    'msg'=> $msg,
                    'data'=>$data, # any data we want to return
                 };
    
    return $status;
}

1;