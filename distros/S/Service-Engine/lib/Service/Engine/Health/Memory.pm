package Service::Engine::Health::Memory;

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

# what's our memory usage looking like?

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
    my $options = $Config->get_config('health')->{'modules'}->{'Memory'}->{'options'};
    if (ref($options) ne 'HASH') {
        $Log->log({'msg'=>"Memory options not found",'level'=>2});
        return {};
    }
    
    my $critical = $options->{'critical'};
    my $warning = $options->{'warning'};
    
    my $os = $^O;
    my $mem_usage = '--';

    if ($os ne 'darwin') { # this chokes on a mac - no /proc table
        use Memory::Usage;
        my $mu = Memory::Usage->new();
 
        # Record amount of memory used by current process
        $mu->record('starting work');
 
        # Spit out a report
        $mem_usage = $mu->report();
    }

###>>>TO DO: need to parse out memory usage and alert accordingly
    
#     my $condition = ($backlog >= $critical) ? 'critical' : ($backlog > $warning) ? 'warning' : 'info';
#     my $state = ($condition eq 'info') ? 'ok' : 'error'; 
#     my $msg = uc($condition) . ": $EngineName queue backlog is $backlog";
#     my $data = {'backlog'=>$backlog, 'condition'=>$condition, 'state'=>$state, 'msg'=>$msg, 'time'=>time()};

    my $condition = 'info';
    my $state = 'ok'; 
    my $msg = uc($condition) . ": " . $EngineName . "::" . $EngineInstance . " memory usage report: $mem_usage";
    my $data = {'condition'=>$condition, 'state'=>$state, 'msg'=>$msg, 'time'=>time()};
    
    my $status = {
                    'state'=>$state, # ok | error
                    'condition'=>$condition, # info|warning|critical
                    'msg'=> $msg,
                    'data'=>$data, # any data we want to return
                 };
    
    return $status;
}

1;