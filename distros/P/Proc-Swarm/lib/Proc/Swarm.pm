#!/usr/bin/perl


package Proc::Swarm;
$Proc::Swarm::VERSION = '1.161060';
use strict;use warnings;
use IPC::Msg;
use Storable;

sub _usage {
    print @_ . "\n" if @_;
    print q(
Proc::Swarm::swarm(
    code     => $coderef,
    children => $child_count,
    work     => \@work_units,
    [sort => 1],
    [debug => 1] );
);
    exit 255;
}

sub swarm {
    my $args = shift;
    _usage() if ref $args ne 'HASH';
    my $coderef = $args->{code};
    my $max_children = $args->{children};
    my @units = @{$args->{work}};
    my $sort_output = $args->{sort};
    my $sort_code = $args->{sort_code};

    my @work_units = @units;
    _usage('No work defined') if (scalar @work_units) == 0;

    _usage('Invalid code passed') unless ref $coderef eq 'CODE';
    _usage('Child count argument must be a non-negative, non-zero integer')
        if $max_children < 1 or $max_children =~ /\./;
    _usage('Work units must not contain a reference')
        if ref $work_units[0];

    #We now have something like clean arguments.

    #We need two message queues.  One that the producer listens to, and
    #another the consumer listens to.  

    my $Qc = Proc::Swarm::Queue->new;    #consumer
    my $Qp = Proc::Swarm::Queue->new;    #producer

    #The main parent is the consumer.  It will exit last.
    #The first child is the producer.
    my $pid = fork();
    if(not defined $pid) {    #fork failed
        die 'Fork failed.  Check your system resources.';
    } elsif(not $pid) {    #Child    (producer)
        my $worker_count = 0;
        my $another_count = 0;
        #first we spin off enough children to max out the count.
        for (1..$max_children) {
            _worker(pop @work_units, $coderef, $Qc);
            $worker_count++;
        }

        #Now we should have $max_children processes.  Wait for them
        #to finish.
        while(1) {
            #We are expecting one of:
            # requests to spawn another worker from the consumer
            # requests from workers to add objects to work list
            # requests from workers to remove objects from work list
            
            my $package = $Qp->receive;
            if($package->get_type eq 'another') {
                $another_count++;
                if($another_count == $worker_count) {
                    #We are now done.
                    $Qc->send(Proc::Swarm::Package->new(undef, 'end'));
                    exit;
                }
        
                if((scalar @work_units) != 0) {
                    _worker(pop(@work_units), $coderef, $Qc);
                    $worker_count++;
                }
            } elsif($package->get_type eq 'del') {
                #find $package->get_object in @work_units and
                #remove it
                my @work_units_tmp;
                my @new_work_units;
                foreach my $work_object (@work_units) {
                    push @new_work_units, $work_object
                        unless $work_object eq $package->get_object;
                }
                undef @work_units;
                foreach (@new_work_units) { push @work_units, $_; }

            } elsif($package->get_type eq 'new') {
                #add $package->get_object into @work_units
                push @work_units, $package->get_object;
            }
        }
    } else {        #Parent    (consumer)
        my @results;
        
        while(1) {
            #We are expecting messages from the workers here.
            #For each worker message, we want to record the result
            #and inform the producer to spawn another worker.
            my $package = $Qc->receive;
            if($package->get_type eq 'res') {
                push @results, $package->get_object;
                #Tell the producer to spawn another worker.
                $Qp->send(
        Proc::Swarm::Package->new(undef, 'another'));
            } elsif($package->get_type eq 'end') {
                #This is a message from the producer that
                #it is finished spawning workers.

                #We will only get this message when we are    
                #sure all of the workers are finished.
                if(defined($sort_output)) { 
                    @results = _sort_results($sort_code, \@results, \@units);
                }
                $Qc->cleanup;
                $Qp->cleanup;
                return Proc::Swarm::Results->new(@results);
            }
        }
    }
}

sub _sort_results {
    my ($sort_code,$results_ref,$units_ref) = @_;

    my @units = @$units_ref;
    my @results = @$results_ref;
    my %sort_hash;
    {   my $i = 0;
        %sort_hash = map { $units[$i], $i++ } @units;
    }

    $sort_code = q(
        sub {   $sort_hash{$a->get_object}
                <=>
                $sort_hash{$b->get_object}
        };
    ) unless defined $sort_code;

    my $sort_coderef = eval $sort_code;

    @results = sort $sort_coderef @results;
    return @results;
}

#this function should immediately return.
sub _worker {
    my ($object,$coderef,$Qc) = @_;

    my ($Qp,$pid);
    #the classic double fork.
    unless ($pid = fork) {
        unless (fork) {
            _worker_worker($object, $coderef, $Qc, $Qp);
            exit 0;
        }
        exit 0;
    }
    waitpid $pid,0;
}

sub _worker_worker {
    my ($object,$coderef,$Qc,$Qp) = @_;
    my $start = scalar time;
    my ($retval,$result_type);

    eval {
        $retval = &$coderef($object); 
    };
    if($@) {
        $result_type = 'error';
        $retval = $@;
    } else {
        $result_type = 'good';
    }
    my $end = scalar time; 
    my $result = Proc::Swarm::Result->new(($end-$start), $object, $retval, $result_type);
    my $package = Proc::Swarm::Package->new($result, 'res');

    $Qc->send($package);
} 

package Proc::Swarm::Package;
$Proc::Swarm::Package::VERSION = '1.161060';
sub new {
    my ($proto,$object,$type) = @_;


    my $class = ref($proto) || $proto;
    my $self = {};
    $self->{type} = $type;
    $self->{obj} = $object;

    bless $self, $class;
    return $self;
}

sub get_type {
    my $self = shift;
    return $self->{type};
}

sub get_object {
    my $self = shift;
    return $self->{obj};
}
package Proc::Swarm::Results;
$Proc::Swarm::Results::VERSION = '1.161060';
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my @results = @_;

    my $self  = {};
    $self->{results} = \@results;
    bless $self, $class;
    return $self;
}

sub get_result_count {
    my $self = shift;
    return $self->{count} if defined $self->{count};
    $self->{count} = scalar @{$self->{results}};
    return $self->{count};
}

sub get_result {
    my $self = shift;
    my $object_id = shift;

    foreach my $result (@{$self->{results}}) {
        return $result
            if $result->get_object eq $object_id;
    }
    return undef;
}

sub get_result_objects {
    my $self = shift;
    return @{$self->{objects}} if defined $self->{objects};

    my @objects;
    foreach my $result (@{$self->{results}}) {
        push @objects, $result->get_result;
    }
    $self->{objects} = \@objects;
    return @objects;
}

sub get_results {
    my $self = shift;
    return @{$self->{results}};
}

sub get_result_times {
    my $self = shift;
    
    return @{$self->{times}} if defined $self->{times};

    my @times;
    foreach my $result (@{$self->{results}}) {
        push @times, $result->get_runtime;
    }
    $self->{times} = \@times;
    return @times;
}

sub get_objects {
    my $self = shift;

    my @objects;
    foreach my $result (@{$self->{results}}) {
        push @objects, $result->get_object;
    }

    return @objects;
}

package Proc::Swarm::Result;
$Proc::Swarm::Result::VERSION = '1.161060';
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self  = {};
    (   $self->{runtime},
        $self->{object},
        $self->{result},$self->{result_type}
    ) = @_;
    bless $self, $class;
    return $self;
}

sub get_runtime {
    my $self = shift;
    return $self->{runtime};
}
sub
get_object {
    my $self = shift;
    return $self->{object};
}

sub get_result {
    my $self = shift;
    return $self->{result};
}

sub get_result_type  {
    my $self = shift;
    return $self->{result_type};
}


package Proc::Swarm::Queue;
$Proc::Swarm::Queue::VERSION = '1.161060';
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    use IPC::SysV qw(IPC_PRIVATE S_IRWXU);

    my $self  = {};

    $self->{Q} = IPC::Msg->new(IPC_PRIVATE, S_IRWXU);

    bless $self, $class;
    return $self;
}

#We can't define a DESTROY method because this class goes out of scope a
#number of times before we actually want to remove the queues.
sub cleanup {
    my $self = shift;
    $self->{Q}->remove;
}

sub send {
    my ($self,$obj) = @_;
    my $frozen_obj = Storable::freeze($obj);
    return $self->{Q}->snd(1, $frozen_obj);    #Message type '1'
}

sub receive {
    my $self = shift;
    my $in_buf;
    my $thing = $self->{Q}->rcv($in_buf, 10240000);#This grabs any message type.
    my $thawed_thing = Storable::thaw $in_buf;
    return $thawed_thing;
}

1;


__END__

=head1 NAME

Proc::Swarm - intelligently handle massive multi-processing on one machine

=head1 SYNOPSIS

    use Proc::Swarm;

    my $code = sub {
        my $arg = shift;
        sleep $arg;
        $arg++;
        return $arg;
    };

    my $retvals = Proc::Swarm::swarm({
        code     => $code,  #code to run
        children => 2,      #How many child processes to run parallel
        sort     => 1,      #sort the results
        work     => [1,5,7,10]
    });    #List of objects to work on
    my @results = $retvals->get_result_objects;
    #@results contain 2, 6, 8 and 11, in numeric order.

    my @run_times = $retvals->get_result_times;
    #how long each took to run.  Should contain something like 1,5,7 and 10

    my @objects = $retvals->get_objects;
    #The objects passed in.  Should contain 1,5,7 and 10

    my $specific_result = $retvals->get_result(10);    
    #Get specific result as keyed by passed object: 11 in this case.

    my $specific_return_value = $retvals->get_result(5)->get_runtime;
    #Returns how long it took to run object 5.

=head1 DESCRIPTION

This module provides some fairly fine control over heavy-duty multiprocessing
work.  This is probably most useful in two general cases: a multi-CPU system
that doesn't distribute load in a single process across all CPUs, and 
programs that need to do a lot of slow, blocking work quickly with many
simultaneous processes.  (For instance, SNMP, SOAP, etc.)  Swarm gathers
the results of all of the child processes together and returns that in a
results object, along with information about the status of each unit of work,
how long it took to run each unit, and related information.

=head1 DESIGN

The parent process will be the consumer, and thus the last to exit.  The
first forked child will be the producer, which will then in turn manage all
of the children.  The consumer listens to message queue Qc, and the
producer listens to Qp.  When the consumer gets an object, that means that
one of the children has finished.  It then sends a massage to Qp telling it
to spawn another child.  That message will be the object to work on.  As
such, the consumer handles the list of all objects to be worked on.

There are some real advantages to this design.  We can cut the working
children free with double fork, since their results come back on the message
queue.  We don't have to handle any dangerous signals.  Both the consumer
and the producer are simplified because they just block on IPC activity.
The producer just double forks every time it gets a message, and then waits
for another message.  The consumer has to look at every message that comes
back.

See the docs/ directory with the distribution for a comprehensive
outline of the included classes.

=head1 TODO

Fix the below-cited limitation of sort functionality.

Add the ability to sort using an arbitrary code reference.

Add the ability to add and remove call objects runtime.

Eventually add the ability to control processes on many different
systems.

Make the timing of each run optionally calculated with HiRes.

=head1 AUTHOR

Dana M. Diederich <diederich@gmail.com>

=head1 BUGS

The sort option sorts under the assumption that there is a one to one
cardinality between the submitted objects and the result objects.  That is,
if a given input object is repeated, and the code that is ran against it
returns more than one different result, the sort system is not guaranteed
to work correctly.

Some of the test suites are rather slow.  One of them is very CPU 
intensive.  While not a bug, this can be rather alarming.

=head1 COPYRIGHT

Copyright (c) 2001, 2013, 2016 Dana M. Diederich. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
  (see http://www.perl.com/perl/misc/Artistic.html)

=cut
