package TaskPipe::ThreadManager;

use Moose;
use Data::Dumper;
use Log::Log4perl;
use Digest::MD5 qw(md5_base64);
use TaskPipe::RunInfo;
use TaskPipe::LoggerManager;
use TaskPipe::SchemaManager;
use TryCatch;
with 'MooseX::ConfigCascade';
#with 'TaskPipe::Role::RunInfo';

has logger_manager => (is => 'ro', isa => 'TaskPipe::LoggerManager', default => sub{
    TaskPipe::LoggerManager->new;
});

has run_info => (is => 'rw', isa => 'TaskPipe::RunInfo', default => sub{
    TaskPipe::RunInfo->new
});

#has job_id => (is => 'rw', isa => 'Str');
has max_threads => (is => 'rw', isa => 'Str');
#has thread_id => (is => 'rw', isa => 'Str');
has forks => (is => 'rw', isa => 'Int');
#with 'TaskPipe::Role::RunInfo';

has gm => (is => 'rw', isa => 'TaskPipe::SchemaManager', required => 1);


sub init{
    my ($self) = @_;

    confess "Need a job id" unless $self->run_info->job_id;

    $self->gm->table('thread')->create({
        job_id => $self->run_info->job_id,
        id => 1,
        parent_id => 0,
        pid => $$,
        parent_pid => 'NONE',
        status => 'processing'
    });
        
    my $num_threads = $self->max_threads;

    if ( $num_threads >= 2 ){

        for my $id (2..$num_threads){
            $self->gm->table('thread')->create({
                job_id => $self->run_info->job_id,
                id => $id,
                status => 'available'
            });
        }
    }
}

sub finalize{
    my ($self) = @_;

    confess "Need a job id" unless $self->run_info->job_id;

    my $logger = Log::Log4perl->get_logger;

    $logger->trace("->finalize routine called");

    $self->gm->table('thread')->search({
        job_id => $self->run_info->job_id
    })->delete_all;
}




sub request_process{
    my ($self) = @_;

    confess "Need a job id" unless $self->run_info->job_id;

    my $logger = Log::Log4perl->get_logger;

    my $reserve_id = "reserved-".md5_base64( $$ * rand );

    my $deadlock;
    my $counter = 0;

    do {
        $deadlock = '';
        try {
            
            $self->gm->schema->txn_do( sub{
                my $rs = $self->gm->table('thread')->search({
                    job_id => $self->run_info->job_id,
                    status => 'available'
                },
                { 
                    rows => 1,
                    'for' => 'update',
                    order_by => { -asc => 'id' }
                });
                $rs->update({
                    status => $reserve_id
                });
            });

        } catch ( DBIx::Error::SerializationFailure $err ) {

            $deadlock = $err;

        } catch ( DBIx::Error $err ){

            confess "Error updating thread table. SQLSTATE = ".$err->state.":\n$err";

        };

    } while ( $deadlock && $counter < 4 );

    confess "Serialization failure while trying to update threads database: ".$deadlock if $deadlock;


    my $row = $self->gm->table('thread')->find({
        job_id => $self->run_info->job_id,
        status => $reserve_id
    });

    my $thread_id;
    $thread_id = $row->id if $row;



    my @resp;

    if ( ! $thread_id ){

        my $check_num_threads = $self->gm->table('thread')->search({
            job_id => $self->run_info->job_id
        })->count;
    
        $logger->trace("There are $check_num_threads threads currently associated with this job");

        if ( $check_num_threads == 0 ){

            @resp = (
                'parent',
                'terminated'
            );

        } else {

            @resp = (
                'parent',       #identity
                'unavailable'  #status
                #$self->run_info->thread_id
            );

        }

    } else {

        my $parent_pid = $$;
        my $parent_thread_id = $self->run_info->thread_id;
        my $pid = fork();
        confess "Fork failed" if not defined $pid;

        if ( $pid ){

            $self->forks( $self->forks + 1 );
            $logger->info("Started thread $thread_id");

            @resp = (
                'parent',
                'ok'
                #$self->run_info->thread_id,
            );

        } else {

            $self->run_info->thread_id( $thread_id );
            $self->logger_manager->init_logger;

            my $deadlock;
            my $counter = 0;

            do {
                try {

                    $self->gm->schema->txn_do( sub{
                        $self->gm->table('thread')->search({
                            job_id => $self->run_info->job_id,
                            id => $thread_id
                        })->update({
                            status => 'processing',
                            pid => $$,
                            parent_pid => $parent_pid,
                            parent_id => $parent_thread_id
                        });
                    });

                } catch ( DBIx::Error::SerializationFailure $err ) {

                    $deadlock = $err;

                } catch ( DBIx::Error $err ){

                    confess "Error updating thread table. SQLSTATE = ".$err->state.":\n$err";

                };
            } while ( $deadlock && $counter < 4 );

            confess "Serialization failure while trying to update threads database: ".$deadlock if $deadlock;


            @resp = ( 
                'child',
                'ok'
                #$thread_id
            );
        }
    }

    return @resp;
}



sub wait_child{
    my $self = shift;

    my $logger = Log::Log4perl->get_logger;

    $logger->debug("Waiting for a child process to terminate");
    my $terminated_pid = wait();
    if ( $terminated_pid == -1 ){   # shouldn't happen, but recalibrate 
        $self->forks( 0 );          # if there is a mismatch
    } else {
        $self->forks( $self->forks - 1 );
        $self->mark_finished( $terminated_pid );
    }
    return $terminated_pid;
}


sub wait_children{
    my $self = shift;

    my $logger = Log::Log4perl->get_logger;

    my $forks = $self->forks;
    if ( $forks ){
        $logger->debug("Waiting for $forks child processes to finish");
        for(1..$forks){
            my $t_pid = $self->wait_child;
            last if $t_pid == -1;
        }
        $logger->debug("All children reaped.");
    }
}



sub mark_finished{
    my ( $self,$pid ) = @_;

    $self->gm->table('thread')->search({
        job_id => $self->run_info->job_id,
        pid => $pid
    })->update({
        status => 'available'
    });
}


sub terminate{
    my ($self) = @_;

    my $logger = Log::Log4perl->get_logger;

    $logger->debug("Terminating process on thread ".$self->run_info->thread_id);
    exit;
}
 

sub execute{
    my ($self,$code,$count,$last_rec_cond) = @_;

    my $logger = Log::Log4perl->get_logger;

    confess "Need code,count,last_rec_cond" unless $code && defined $last_rec_cond && $count;
    confess "code should be a code_ref" unless ref $code eq ref(sub{});

    $logger->trace("count is $count at beginning of execute");

    if ( $last_rec_cond ){

        $logger->trace("Last record in loop - self executing");            
        #$code->($self->run_info->thread_id);
        $code->();

    } else {

        my ($ident,$status) = $self->request_process;

        if ( $ident eq 'parent' && $status eq 'unavailable' ){

            $logger->trace("count: $count got unavailable status");

            if ( $self->forks ){

                $logger->trace("count: $count Waiting for an available thread");
                my $pid = $self->wait_child;
                $logger->trace("count: $count A process finished (pid $pid). Continuing");

            } else {

                $logger->trace("Parent executing task directly");
                #$code->($thread_id);
                $code->();

            }

        }

        if ( $ident eq 'parent' && $status eq 'terminated' ){

            $logger->info("Looks like some kind of error was encountered. Terminating");
            $self->terminate;

        }

        if ( $ident eq 'child' ){

            #$code->($thread_id);
            $code->();
            $self->terminate;

        }
    }
}

=head1 NAME

TaskPipe::ThreadManager - manages threads for TaskPipe

=head1 DESCRIPTION

Using this module directly is not recommended. See the general manpages for Taskpipe.

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

__PACKAGE__->meta->make_immutable;
1;      
