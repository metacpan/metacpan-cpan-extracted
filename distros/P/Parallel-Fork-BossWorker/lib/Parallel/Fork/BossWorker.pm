package Parallel::Fork::BossWorker;
#
# $Id: BossWorker.pm 11 2011-07-16 15:49:45Z twilde $
#

use 5.008008;
use strict;
use warnings;
use Carp;
use Data::Dumper qw(Dumper);
use IO::Handle;
use IO::Select;

# Perl module variables
our @ISA = qw();
our $VERSION = '0.05';

sub new {
    my $class = shift;
    my %values = @_;
    
    my $self = {
        result_handler => $values{result_handler} || undef,  # Method for handling output of the workers
        worker_count   => $values{worker_count}   || 10,     # Number of workers
        global_timeout => $values{global_timeout} || 0,      # Number of seconds before the worker terminates the job, 0 for unlimited
        work_handler   => $values{work_handler},             # Handler which will process the data from the boss
        work_queue     => [],
        msg_delimiter  => $values{msg_delimiter} || "\0\0\0",
        select         => IO::Select->new(),
    };
    $self->{msg_delimiter_length} = length($self->{msg_delimiter});
    bless $self, ref($class) || $class;

    # The work handler is required
    if (not defined $self->{work_handler}) {
        croak("Parameters \`work_handler' is required.");
    }

    return $self;
}

sub add_work(\@) {
    my $self = shift;
    my $work = shift;
    unshift (@{ $self->{work_queue} }, $work);
}

sub process {
    my $self = shift;
    my $handler = shift;
    
    eval {
        
        # If a worker dies, there's a problem
        local $SIG{CHLD} = sub {
            my $pid = wait();
            if (defined $self->{workers}->{$pid}) {
                confess("Worker $pid died.");
            }
        };
        
        # Start the workers
        $self->start();
        
        # Read from the workers, loop until they all shut down
        while (%{$self->{workers}}) {
            while (my @ready = $self->{select}->can_read()) {
                foreach my $fh (@ready) {
                    my $result = $self->receive($fh);
                    if (!$result) {
                        $self->{select}->remove($fh);
                        print STDERR "$fh got eof\n";
                        next;
                    }
                    
                    # Process the result handler
                    if ($result->{data} && defined $self->{result_handler}) {
                        &{ $self->{result_handler} }( $result->{data} );
                    }
                    
                    # If there's still work to be done, send it to the worker, otherwise shut it down
                    if ($#{ $self->{work_queue} } > -1) {
                        my $worker = $self->{workers}->{$result->{pid}};
                        $self->send(
                            $self->{workers}->{ $result->{pid} }, # Worker's pipe
                            pop(@{ $self->{work_queue} })
                        );
                    } else {
                        $self->{select}->remove($fh);
                        my $fh = $self->{workers}->{ $result->{pid} };
                        delete($self->{workers}->{ $result->{pid} });
                        close($fh);
                    }
                }
            }
        }
        
        # Wait for our children so the process table won't fill up
        while ((my $pid = wait()) != -1) { }
    };
    
    if ($@) {
        croak($@);
    }
}

sub start {
    my $self = shift();
    
    # Create a pipe for the workers to communicate to the boss
    
    # Create the workers
    foreach (1..$self->{worker_count}) {
        
        # Open a pipe for the worker
        pipe(my $from_boss, my $to_worker);
        pipe(my $from_worker, my $to_boss);
        
        # Fork off a worker
        my $pid = fork();
        
        if ($pid > 0) {
            
            # Boss
            $self->{workers}->{$pid} = $to_worker;
            $self->{from_worker}->{$pid} = $from_worker;
            $self->{select}->add($from_worker);

            # Close unused pipes
            close($to_boss);
            close($from_boss);
            
        } elsif ($pid == 0) {
            
            # Worker
            
            # Close unused pipes
            close($from_worker);
            close($to_worker);
            
            # Setup communication pipes
            $self->{to_boss} = $to_boss;
            open(STDIN, '/dev/null');
            
            # Send the initial request
            $self->send($to_boss, {pid => $$});
            
            # Start processing
            $self->worker($from_boss);
            
            # When the worker subroutine completes, exit
            exit;
        } else {
            confess("Failed to fork: $!");
        }
    }
}

sub worker(\*) {
    my $self = shift();
    my $from_boss = shift();
    
    # Read instructions from the server
    while (my $instructions = $self->receive($from_boss)) {
        
        # If the handler's children die, that's not our business
        $SIG{CHLD} = 'IGNORE';
        
        # Execute the handler with the given instructions
        my $result;
        eval {
            # Handle alarms
            local $SIG{ALRM} = sub {
                die "Work handler timed out."
            };
            
            # Set alarm
            alarm($self->{global_timeout});
            
            # Execute the handler and get it's result
            if (defined $self->{work_handler}) {
                $result = &{ $self->{work_handler} }($instructions);
            }
            
            # Disable alarm
            alarm(0);
        };
        
        # Warn on errors
        if ($@) {
            croak("Worker $$ error: $@");
        }
        
        # Send the result to the server
        $self->send($self->{to_boss}, {pid => $$, data => $result});
    }
}

sub receive(\*) {
    my $self = shift();

    # Get the file handle
    my $fh = shift();
    
    # Get a value from the file handle
    my $value;
    my $char;
    while (read($fh, $char, 1)) {
        $value .= $char;
        if (substr($value, -($self->{msg_delimiter_length})) eq $self->{msg_delimiter}) {
            $value = substr($value, 0, -($self->{msg_delimiter_length}));
            last;
        }
    }
    
    # Deserialize the data
    no strict;
    no warnings;
    my $data = eval($value);

    if ($@) {
        print STDERR "Value: '$value'\n" if $ENV{PFBW_DEBUG};
        confess("Failed to deserialize data: $@");
    }

    return $data;
}

sub send(\*$) {
    my $self = shift();

    # Get the file handle
    my $fh = shift();

    # Get the value which will be sent
    my $value = shift();

    # Print the value to the file handle
    local $Data::Dumper::Deepcopy = 1;
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Purity = 1;
    print $fh Dumper($value) . $self->{msg_delimiter};
    
    # Force the file handle to flush
    $fh->flush();
}

1;
__END__

=head1 NAME

Parallel::Fork::BossWorker - Perl extension for easiliy creating forking queue processing applications.

=head1 SYNOPSIS

The minimal usage of Parallel::Fork::BossWorker requires you supply
the work_handler argument which returns a hash reference.

    use Parallel::Fork::BossWorker;
    
    # Create new BossWorker instance
    my $bw = Parallel::Fork::BossWorker->new(
        work_handler => sub {
            my $work = shift;
            ... do work here ...
            return {};
        }
    );
    
    $bw->add_work({key=>"value"});
    $bw->process();

Additionally, you could specify the result_handler argument, which
is passed the hash reference returned from your work_handler.

    use Parallel::Fork::BossWorker;
    
    # Create new BossWorker instance
    my $bw = Parallel::Fork::BossWorker->new(
        work_handler => sub {
            my $work = shift;
            ... do work here ...
            return {result => "Looks good"};
        },
        result_handler => sub {
            my $result = shift;
            print "$result->{result}\n";
        }
    );

=head1 DESCRIPTION

Parallel::Fork::BossWorker makes creating multiprocess applications easy.

The module is designed to work in a queue style of setup; with the worker
processes requesting 'work' from the boss process. The boss process
transparently serializes and sends the work data to your work handler, to be
consumed and worked. The worker process then transparently serializes and sends
optional data back to the boss process to be handled in your result handler.

This process repeats until the work queue is empty.

=head1 METHODS

=head2 new(...)

Creates and returns a new Parallel::Fork::BossWorker object.

    my $bw = Parallel::Fork::BossWorker->new(work_handler => \&routine)

Parallel::Fork::BossWorker has options which allow you to customize
how exactly the queue is handled and what is done with the data.

=over 4

=item * C<< work_handler => \&routine >>

The work_handler argument is required, the sub is called with it's first
and only argument being one of the values in the work queue. Each worker calls
this sub each time it receives work from the boss process. The handler may trap
$SIG{ALRM}, which may be called if global_timeout is specified.

The work_handler should clean up after itself, as the workers may call the
work_handler more than once.

=item * C<< result_handler => \&routine >>

The result_handler argument is optional, the sub is called with it's first
and only argument being the return value of work_handler. The boss process
calls this sub each time a worker returns data. This subroutine is not affected
by the value of global_timeout.

=item * C<< global_timeout => $seconds >>

By default, a handler can execute forever. If global_timeout is specified, an
alarm is setup to terminate the work_handler so processing can continue.

=item * C<< worker_count => $count >>

By default, 10 workers are started to process the data queue. Specifying
worker_count can scale the worker count to any number of workers you wish.

Take care though, as too many workers can adversely impact performance, though
the optimal number of workers will depend on what your handlers do.

=item * C<< msg_delimiter => $delimiter >>

Sending messages to and from the child processes is accomplished using
Data::Dumper. When transmitting data, a delimiter must be used to identify the
breaks in messages. By default, this delimiter is "\0\0\0", this delimiter may
not appear in your data.

=head2 add_work(\%work)

Adds work to the instance's queue.

    $bw->add_work({data => "my data"});

=head2 process()

Forks off the child processes and begins processing data.

    $bw->process();

=head1 REQUIREMENTS

This module depends on the following modules:

Carp

Data::Dumper

IO::Handle

IO::Select

=head1 BUGS

If we knew about any bugs, we would have fixed them. :)

=head1 SEE ALSO

=head1 AUTHOR

Jeff Rodriguez, E<lt>jeff@jeffrodriguez.comE<gt>

Tim Wilde, E<lt>twilde@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007, Jeff Rodriguez

Portions Copyright (c) 2011, Tim Wilde

All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
