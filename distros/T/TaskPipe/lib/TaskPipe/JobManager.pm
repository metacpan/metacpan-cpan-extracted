package TaskPipe::JobManager;

use Moose;
use Carp;
use Proc::ProcessTable;
use TaskPipe::TorManager;
use TaskPipe::JobManager::Settings;
use Log::Log4perl;
use DateTime;
use Try::Tiny;
use File::Path 'rmtree';

#has job_id => (is => 'rw', isa => 'Int');

has run_info => (is => 'rw', isa => 'TaskPipe::RunInfo', default => sub{
    TaskPipe::RunInfo->new
});

has name => (is => 'rw', isa => 'Str');
has project => (is => 'rw', isa => 'Str');

has exempt => (is => 'rw', isa => 'Bool', default => 0);

# Allow these commands to proceed without being recorded on job table even if database connect fails
# This is necessary because we need to be able to execute these commands before the db is set up
has exemptions => (is => 'ro', isa => 'ArrayRef', default => sub{[
    'Setup',
    'GenerateSchema',
    'DeployTables'
]}); 




has gm => (is => 'rw', isa => 'TaskPipe::SchemaManager', lazy => 1, default => sub{
    my ($self) = @_;

    my $gm = TaskPipe::SchemaManager->new( scope => 'global' );

    try {
        $gm->connect_schema;
    } catch {
        if ( grep { $_ eq $self->name } @{$self->exemptions} ){
            warn "Could not register job as database is unavailable. Proceeding without job_id: this command is exempt";
            $self->exempt(1);
        } else {
            die "$_\n";
        }
    };

    return $gm;
});

has settings => (is => 'ro', isa => 'TaskPipe::JobManager::Settings', default => sub{
    TaskPipe::JobManager::Settings->new;
});

has port_manager => (is => 'ro', isa => 'TaskPipe::PortManager', lazy => 1, default => sub{
    TaskPipe::PortManager->new( gm => $_[0]->gm );
});






sub init_job{
    my ($self) = @_;

    $self->gm; # force connection attempt
    return if $self->exempt;

    my $insert = {};
    foreach my $param ( qw(name project) ){
        confess "Need a $param" unless $self->$param;
        $insert->{$param} = $self->$param;
    }

    $insert->{pid} = $$;
    $insert->{orig_cmd} = "@{$self->run_info->orig_cmd}";
    $insert->{created_dt} = DateTime->now;

    $self->clean_tables;

    my $job_row = $self->gm->table('job')->create($insert);
    confess "Job failed: Unable to register job in database" unless $job_row;

    $self->run_info->job_id( $job_row->id );
    return $job_row->id;
} 
       


sub end_job{
    my ($self) = @_;

    return if $self->exempt;

    confess "Need a job_id" unless defined $self->run_info->job_id;

    $self->stop_spawned;

    $self->gm->schema->txn_do( sub{
        $self->gm->table('thread')->search({
            job_id => $self->run_info->job_id
        })->delete_all;
        $self->gm->table('job')->search({
            id => $self->run_info->job_id
        })->delete_all;
    });
}



sub stop_spawned {
    my ($self, $job_id) = @_;

    $job_id ||= $self->run_info->job_id;

    my $spawned_rs = $self->gm->table('spawned')->search({
        job_id => $job_id
    });

    while( my $spawned = $spawned_rs->next ){

        kill 'KILL', $spawned->pid;
        if ( $spawned->temp_dir ){
            rmtree( $spawned->temp_dir );
        }
        $spawned->delete;

    }

}




sub daemonize{
    my $self = shift;

    $self->fork_safely and exit;
    POSIX::setsid();
    $self->fork_safely and exit;

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

    my $t = Proc::ProcessTable->new;

    my $active = 0;

    foreach my $p ( @{$t->table} ){ 
        if ( $p->pid eq $pid ){
            $active = 1;

            # sanity check to make sure this really is the
            # original process
            my @orig_cmd = split( /\s+/, $orig_cmd );
            foreach my $arg ( @orig_cmd ){
                $active = 0 unless $p->cmndline =~ /$arg/;
            }
        }
    }

    return $active;
}


sub clean_tables{
    my $self = shift;

    my $procs_rs = $self->gm->table('job')->search;    

    # remove table rows from job and thread which no longer have active processes
    while( my $proc_row = $procs_rs->next ){

        my $parent_active = 0;
        my $threads_active = 0;

        $parent_active = $self->process_active($proc_row->pid, $proc_row->orig_cmd);

        # if parent not active, it doesn't mean the process is not running - 
        # the parent could have died but left children active
        my $threads_rs;
        if ( ! $parent_active ){

            $threads_rs = $self->gm->table('thread')->search({
                job_id => $proc_row->id
            });

            while( my $thread = $threads_rs->next ){
                if ( $thread->pid && $self->process_active($thread->pid,$proc_row->orig_cmd)){
                    $threads_active = 1;
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
}


sub stop_job{
    my ($self,$job_id) = @_;

    confess "job_id must be provided" unless defined $job_id;

    $self->clean_tables;

    my %rs;
    $rs{job} = $self->gm->table('job')->search({
            id => $job_id
    });
    $rs{thread} = $self->gm->table('thread')->search({
        job_id => $job_id
    });

    confess "Unable to find an active job with id=".$self->run_info->job_id." - perhaps this process is already dead?" unless $rs{job}->count || $rs{thread}->count;

    my $active;
    my $count = 0;

    do {

        $active = 0;
        my $t = Proc::ProcessTable->new;

        my $procs_rs = $self->gm->table('job')->search({
            id => $job_id
        });
   
        while( my $proc_row = $procs_rs->next ){

            if ( $self->process_active($proc_row->pid, $proc_row->orig_cmd) ){
                $active = 1;
                kill 'KILL', $proc_row->pid;
            }

            my $threads_rs = $self->gm->table('thread')->search({
                job_id => $proc_row->id
            });

            while( my $thread = $threads_rs->next ){

                if ( $thread->pid && $self->process_active($thread->pid, $proc_row->orig_cmd) ){
                    $active = 1;
                    kill 'KILL', $thread->pid
                }
            }
        }

        $count++;
        confess "Failed to stop job $job_id after $count attempts: unknown error" if $count > $self->settings->max_kill_job_attempts;

    } while ( $active );
    
    $self->stop_spawned( $job_id );

    $self->clean_tables;

}




sub list_jobs{
    my ($self,@cols) = @_;

    $self->clean_tables;

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
