package TaskPipe::JobManager;

use Moose;
use Carp;
use Proc::ProcessTable;
use TaskPipe::JobManager::Settings;
use Log::Log4perl;
use DateTime;
use Try::Tiny;
use File::Path 'rmtree';
use Data::Dumper;
use TaskPipe::PortManager;

#has job_id => (is => 'rw', isa => 'Int');

has run_info => (is => 'rw', isa => 'TaskPipe::RunInfo', default => sub{
    TaskPipe::RunInfo->new
});

has name => (is => 'rw', isa => 'Str');
has project => (is => 'rw', isa => 'Str');

has gm => (is => 'rw', isa => 'TaskPipe::SchemaManager', lazy => 1, default => sub{
    my ($self) = @_;

    my $gm = TaskPipe::SchemaManager->new( scope => 'global' );
    $gm->connect_schema;
    return $gm;
});

has settings => (is => 'ro', isa => 'TaskPipe::JobManager::Settings', default => sub{
    TaskPipe::JobManager::Settings->new;
});

has port_manager => (is => 'ro', isa => 'TaskPipe::PortManager', lazy => 1, default => sub{
    TaskPipe::PortManager->new( gm => $_[0]->gm );
});

has proc_lookup => (is => 'rw', isa => 'HashRef', lazy => 1, builder => 'build_proc_lookup');



sub build_proc_lookup{
    my ($self) = @_;

    my $t = Proc::ProcessTable->new;

    my $lookup = {};
    foreach my $p ( @{$t->table} ){ 
        $lookup->{ $p->pid } = $p->cmndline;
    }
    return $lookup;
}




sub init_job{
    my ($self) = @_;

    my $logger = Log::Log4perl->get_logger;

    return if $self->settings->job_tracking ne 'register';
    $self->gm; #:force connection attempt FIXME

    my $insert = {};
    foreach my $param ( qw(name project) ){
        confess "Need a $param" unless $self->$param;
        $insert->{$param} = $self->$param;
    }

    $insert->{pid} = $$;
    $insert->{orig_cmd} = "@{$self->run_info->orig_cmd}";
    $insert->{created_dt} = DateTime->now;
    $insert->{shell} = $self->run_info->shell;

    $self->clean_tables;

    $logger->debug("Recording start of job");
    my $job_row = $self->gm->table('job')->create($insert);
    confess "Job failed: Unable to register job in database" unless $job_row;

    $self->run_info->job_id( $job_row->id );
    $logger->debug("Job ".$job_row->id." started");

    return $job_row->id;
} 
       


sub end_job{
    my ($self) = @_;

    return if $self->settings->job_tracking ne 'register';

    confess "Need a job_id" unless defined $self->run_info->job_id;

    $self->stop_spawned;

    $self->gm->schema->txn_do( sub{
        $self->gm->table('spawned')->search({
            process_name => "thread",
            job_id => $self->run_info->job_id
        })->delete_all;
        $self->gm->table('job')->search({
            id => $self->run_info->job_id
        })->delete_all;
    });
}



sub stop_spawned {
    my ($self, $job_id) = @_;

    my $logger = Log::Log4perl->get_logger;

    $job_id ||= $self->run_info->job_id;


    my $spawned_rs = $self->gm->table('spawned')->search({
        job_id => $job_id
    });

    while( my $spawned = $spawned_rs->next ){

        my $pid = $spawned->pid;
        $logger->debug("Stopping process $pid");
        kill 'KILL', $pid;
        if ( $spawned->temp_dir ){
            rmtree( $spawned->temp_dir );
        }
        $spawned->delete;

    }

}




sub daemonize{
    my $self = shift;

    $self->gm->table('job')->find({
        id => $self->run_info->job_id
    })->update({
        shell => $self->run_info->shell
    });

    $self->fork_safely and exit;
    POSIX::setsid();
    my $new_pid = $self->fork_safely;
 
    if ( $new_pid ){
        $self->gm->table('job')->find({
            id => $self->run_info->job_id
        })->update({
            pid => $new_pid
        });
        exit;
    }

    umask 0;
    chdir '/';
    close STDIN;
    close STDOUT;
    close STDERR;

}



sub fork_safely{
    my $self = shift;

    my $pid = fork;
    confess "Fork failed" unless defined $pid;
    return $pid;
}


sub process_active{
    my ($self,$pid,$orig_cmd) = @_;

    confess "Need a pid" unless $pid;

    my $logger = Log::Log4perl->get_logger;

    my $active = 0;

    if ( $self->proc_lookup->{$pid} ){

        $active = 1;
        $active = 0 unless $self->proc_lookup->{$pid} =~ /taskpipe/;

    }

    return $active;
}

            



sub clean_tables{
    my $self = shift;

    my $logger = Log::Log4perl->get_logger;
    $logger->debug("Cleaning job table...");

    my $procs_rs = $self->gm->table('job')->search({});;    

    # remove table rows from job and thread which no longer have active processes
    while( my $proc_row = $procs_rs->next ){

        my $parent_active = 0;
        my $threads_active = 0;

        $parent_active = $self->process_active($proc_row->pid);

        # if parent not active, it doesn't mean the process is not running - 
        # the parent could have died but left children active
        my $threads_rs;
        if ( ! $parent_active ){

            $threads_rs = $self->gm->table('spawned')->search({
                process_name => 'thread',
                job_id => $proc_row->id
            });

            while( my $thread = $threads_rs->next ){
                if ( $thread->pid && $self->process_active($thread->pid,$proc_row->orig_cmd)){
                    $threads_active = 1;
                    last;
                }
            }
        }
        
        if ( ! $parent_active && ! $threads_active ){
            $self->stop_spawned( $proc_row->id );
            $self->port_manager->clear_ports( $proc_row->id );
            $threads_rs->delete;
            $proc_row->delete;
        }
    }

    $logger->debug("Done cleaning job table");
}


sub stop_job{
    my ($self,$job_id) = @_;

    my $logger = Log::Log4perl->get_logger;

    confess "job_id must be provided" unless defined $job_id;

    $self->clean_tables;

    my %rs;
    $rs{job} = $self->gm->table('job')->search({
            id => $job_id
    });
    $rs{thread} = $self->gm->table('spawned')->search({
        process_name => 'thread',
        job_id => $job_id
    });

    confess "Unable to find an active job with id=".$self->run_info->job_id." - perhaps this process is already dead?" unless $rs{job}->count || $rs{thread}->count;

    my $active;
    my $count = 0;

    do {

        $active = 0;

        my $procs_rs = $self->gm->table('job')->search({
            id => $job_id
        });
   
        $self->proc_lookup( $self->build_proc_lookup );
        while( my $proc_row = $procs_rs->next ){

            if ( $self->process_active($proc_row->pid) ){
                $logger->debug("Killing job pid ".$proc_row->pid);
                $active = 1;
                kill 'KILL', $proc_row->pid;
            }

            my $threads_rs = $self->gm->table('spawned')->search({
                process_name => 'thread',
                job_id => $proc_row->id
            });

            while( my $thread = $threads_rs->next ){

                if ( $thread->pid && $self->process_active($thread->pid) ){
                    $logger->debug("Killing thread pid ".$thread->pid);
                    $active = 1;
                    kill 'KILL', $thread->pid;
                }
            }
        }

        $count++;
        confess "Failed to stop job $job_id after $count attempts: unknown error" if $count > $self->settings->max_kill_job_attempts;

    } while ( $active );
    
    $self->stop_spawned( $job_id );

}




sub list_jobs{
    my ($self,@cols) = @_;

    #$self->clean_tables;

    my $jobs_rs = $self->gm->table('job')->search;

    my $list = [];
    while (my $job = $jobs_rs->next ){
        my $li = [];
        foreach my $col (@cols){
            push @$li,$job->$col
        }
        push @$list,$li;
    }

    return $list;
}


=head1 NAME

TaskPipe::JobManager - manages TaskPipe jobs

=head1 DESCRIPTION

It is not recommended to use this module directly. See the general manpages for TaskPipe

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

__PACKAGE__->meta->make_immutable;
1;
