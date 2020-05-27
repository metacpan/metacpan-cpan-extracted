package Service::Engine::Threads;
use strict;

use 5.010;
use strict;
use warnings;
use Carp;
use Service::Engine;
use Data::Dumper;

use threads;
use threads::shared;
use Thread::Queue;

our $Config;
our $Log;
our $EngineName;
our $EngineConfig;
our $Modules;
our $ModuleMethods;
our $ThreadCount = 0;
our $ThreadQueue= [];
our $Throughput;
our $Alert;
share($Throughput);
share($ThreadCount);
share($ThreadQueue);

sub new {

    my ($class,$options) = @_;
    
    # set some defaults
    my $attributes = {'threads'=>[]};
    
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
	$EngineConfig = $Service::Engine::EngineConfig;
	$Modules = $Service::Engine::Modules;
	$ModuleMethods = $Service::Engine::ModuleMethods;
	$Throughput = $Service::Engine::Throughput;
	$Alert = $Service::Engine::Alert;
	
	my $ThreadQueue_to_start = $Config->get_config('engine')->{'threads'};
	$ThreadQueue_to_start ||= 5;
	
	$Log->log({msg=>"loading $ThreadQueue_to_start threads",level=>2});

	my @carriers :shared = ();
    while (scalar(@carriers) < $ThreadQueue_to_start) {
    	my $queue :shared = Thread::Queue->new();
        my $thread = threads->new( 'queue', $queue);
        my $thread_id :shared = $thread->tid;
        my %carrier_obj :shared = ('queue'=>$queue,'thread_id'=>$thread_id);
        push @carriers, \%carrier_obj;
    }
    
    $ThreadCount = scalar(@carriers);
    $Log->log({msg=>"LOADED $ThreadCount threads",level=>3});

    if ( @carriers < 1 ) {
        croak('failed to load threads');
    }
    
    $ThreadQueue= \@carriers;

    my $self = bless $attributes, $class;
    
    return $self;
    
}

sub queue {
    my ($thread) = @_;
    my $method = $ModuleMethods->{'worker'}->{'method'};
    # Each thread needs it own $Data
    my $data = Service::Engine::Data->new();
    $Log->log({msg=>"setting up data",level=>2});
    while ( (my $item = $thread->dequeue) ) {
        my $queue_item = {'data'=>$data, 'item'=>$item, 'id'=> threads->tid()};
        $Modules->{'worker'}->$method($queue_item);
        if ($Throughput) {
            $Throughput->finish();
        }
    }    
}

sub add_thread {
    my ($self, $fh, $queue_id) = @_;
    
    my $queue :shared = Thread::Queue->new();
    my $thread = threads->new( 'queue', $queue);
    my $thread_id :shared = $thread->tid;
    my %carrier_obj :shared = ('queue'=>$queue,'thread_id'=>$thread_id);
    if ($queue_id) {
        $ThreadQueue->[$queue_id] = \%carrier_obj;
    } else {
        push @{$ThreadQueue}, \%carrier_obj;
    }
    
    $ThreadCount += 1;
    $Log->log({msg=>"adding 1 thread",level=>3});
    if ($fh) {
        warn(Dumper($fh));
        $fh->write("Added 1 Thread");
    }
    return '';
}

sub get_thread {
    my ($self) = @_;
    # Get a random number between 0 and $self->{thread_count}
    my $rand = int(rand(scalar(@{$ThreadQueue}))); 
    warn(Dumper($ThreadQueue->[$rand]));
    my $carrier = $ThreadQueue->[$rand];
    my $queue = $carrier->{'queue'};
    my $thread_id = $carrier->{'thread_id'};
    my $thr = threads->object($thread_id);
    if (my $err = $thr->error()) {
        $Log->log({msg=>"Thread $thread_id queue:$rand error: $err\n",level=>0});
        # need to support alerting here
        # $Alert->send({'msg'=>"Thread $thread_id queue:$rand error: $err",'module'=>'Twilio', 'handle'=>'sms', 'options'=>$handle_config});
        # create a new thread in this slot
        $self->add_thread(undef,$rand);
        return $ThreadQueue->[$rand]->{'queue'};
    }
    
    return $queue;
}

sub get_thread_count {
    my ($self) = @_;   
    return scalar(@{$ThreadQueue});
}

sub get_queue_count {
    my ($self) = @_;
    my $count = 0;
    foreach my $carrier (@{$ThreadQueue}) {
        my $queue = $carrier->{'queue'};
    	$count += $queue->pending();
    }
    return $count;
}

1;