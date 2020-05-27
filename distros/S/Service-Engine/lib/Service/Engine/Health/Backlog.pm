package Service::Engine::Health::Backlog;

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

# what's our backlog?

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
    my $options = $Config->get_config('health')->{'modules'}->{'Backlog'}->{'options'};
    if (ref($options) ne 'HASH') {
        $Log->log({'msg'=>"Backlog options not found",'level'=>2});
        return {};
    }
    
    my $critical = $options->{'critical'};
    my $warning = $options->{'warning'};
    my $total_backlog = $Threads->get_queue_count();
    my $thread_count = $Threads->get_thread_count();
    $thread_count ||= 1;
    my $backlog = $total_backlog / $thread_count;
    
    my $condition = ($backlog >= $critical) ? 'critical' : ($backlog > $warning) ? 'warning' : 'info';
    my $state = ($condition eq 'info') ? 'ok' : 'error'; 
    my $msg = uc($condition) . ": $EngineName:$EngineInstance average thread backlog is $backlog, queue backlog is $total_backlog";
    my $data = {'total_backlog'=>$total_backlog, 'average_backlog'=>$backlog, 'condition'=>$condition, 'state'=>$state, 'msg'=>$msg, 'time'=>time()};
    
    my $status = {
                    'state'=>$state, # ok | error
                    'condition'=>$condition, # info|warning|critical
                    'msg'=> $msg,
                    'data'=>$data, # any data we want to return
                 };
    
    return $status;
}

1;