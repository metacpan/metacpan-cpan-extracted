package TaskPipe::ThreadManager;

use Moose;
use Data::Dumper;
use Log::Log4perl;
use Digest::MD5 qw(md5_base64);
use TaskPipe::RunInfo;
use Module::Runtime 'require_module';
use TaskPipe::LoggerManager;
use TaskPipe::SchemaManager;
use TryCatch;
use Proc::ProcessTable;
use Proc::Exists qw(pexists);
use DateTime;
use Carp qw(confess longmess);


with 'MooseX::ConfigCascade';


has utils => (is => 'ro', isa => 'TaskPipe::TaskUtils');

has logger_manager => (is => 'ro', isa => 'TaskPipe::LoggerManager', default => sub{
    TaskPipe::LoggerManager->new;
});

has run_info => (is => 'rw', isa => 'TaskPipe::RunInfo', default => sub{
    TaskPipe::RunInfo->new;
});


has settings => (is => 'rw', isa => __PACKAGE__.'::Settings', default => sub{
    my $module = __PACKAGE__.'::Settings';
    require_module( $module );
    my $settings = $module->new;
    return $settings;
});


has gm => (is => 'rw', isa => 'TaskPipe::SchemaManager', required => 1);
has sm => (is => 'rw', isa => 'TaskPipe::SchemaManager', required => 1);


sub init{
    my ($self) = @_;

    my $logger = Log::Log4perl->get_logger;
    $SIG{CHLD} = 'IGNORE';

#    print "run info: ".Dumper( $self->run_info )."\n";
#    print longmess("Stack Trace: ");

    confess "Need a job id" unless +$self->run_info->job_id;

    my $conf = MooseX::ConfigCascade::Util->conf;    
    my $conf_serialized = $self->utils->serialize( $conf );

    my $job_row = $self->gm->table('job')->find({
        id => $self->run_info->job_id
    });

    confess "Could not find a row on the job table with job id ".$self->run_info->job_id unless $job_row;

    $job_row->update({
        conf => $conf_serialized
    });
        
    my $thread_count = $self->sm->table('thread')->search({})->count;
    $self->top_up_thread_slots;

    # judge (and return) the run situation from the state of the
    # thread table

    return "start" unless $thread_count;

    $self->sm->table('thread')->search({
        data => undef
    })->update({
        status => 'available'
    });

    my $resume_threads = $self->sm->table('thread')->search({
        data => { '!=', undef }
    });

    if ( $resume_threads->count ){
        $resume_threads->update({
            status => 'ready'
        });
        return "resume";
    }

    return "stop";

}




#    my $max_threads = $self->settings->max_threads;

#    my $resume_threads = $self->sm->table('thread')->search({});
#    my $num_resume_threads = $resume_threads->count;

#    if ( $max_threads > $num_resume_threads ){
#        my $start = $num_resume_threads + 1;
#        
#        for my $id ($start..$max_threads){
#            $self->sm->table('thread')->create({
#                id => $id,
#                status => 'available'
#            });
#        }
#    }
#}





sub manage{
    my ($self) = @_;

    my $logger = Log::Log4perl->get_logger;
    my $count;

    $logger->trace("Starting manage subroutine");
    $logger->info("pid $$ started manage sub");

    use Carp 'longmess';
    $logger->info("manage: ".longmess("trace:"));
#    do {

    while(1){
        $self->top_up_thread_slots;
        $self->start_forks;
        $self->clean_thread_table;

        $count = $self->sm->table('thread')->search({
            status => 'available'
        });

        if ( $count == +$self->settings->max_threads ){
            sleep 1;
            $count = $self->sm->table('thread')->search({
                status => 'available'
            });
            last if $count == +$self->settings->max_threads;
        }
    }
#    } while ( $count <= +$self->settings->max_threads );

    $logger->debug("Leaving manage subroutine");

}




    



sub request_process{
    my ($self) = @_;

    confess "Need a job id" unless $self->run_info->job_id;

    my $logger = Log::Log4perl->get_logger;

    $logger->debug("Requesting process");

    #my $reserve_id = "reserved-".md5_base64( $$ * rand );
    my $token = md5_base64( $$ * rand );

    my $deadlock;
    my $counter = 0;

    do {
        $deadlock = '';
        try {
            
            $self->gm->schema->txn_do( sub{
                my $rs = $self->sm->table('thread')->search({
                    status => 'available'
                },
                { 
                    rows => 1,
                    'for' => 'update',
                    order_by => { -asc => 'id' }
                });
                $rs->update({
                    token => $token,
                    status => 'reserved'
                });
            });

        } catch ( DBIx::Error::SerializationFailure $err ) {

            $deadlock = $err;

        } catch ( DBIx::Error $err ){

            confess "Error updating thread table. SQLSTATE = ".$err->state.":\n$err";

        };

        $counter++;

    } while ( $deadlock && $counter < +$self->settings->thread_table_deadlock_retries );

    confess "Serialization failure while trying to update threads database: ".$deadlock if $deadlock;

    my $row = $self->sm->table('thread')->find({
        status => 'reserved',
        token => $token
    });
    $logger->trace("Ending request_process subroutine");

    return unless $row;

    $row->update({
        status => 'ready'
    });
    return $row;
}


#sub mark_finished{
#    my ($self) = @_;

#    $self->gm->table('thread')->search({
#        pid => $$
#    })->update({
#        status => 'available'
#    });
#}


sub stop_threads{
    my ($self) = @_;

    $self->sm->table('thread')->search({})->update({
        status => 'stopping'
    });
}




sub mark_finished{
    my ($self) = @_;

    $self->sm->table('xresult')->search({
        thread_id => +$self->run_info->thread_id
    })->delete;

    $self->sm->table('xbranch')->search({
        thread_id => +$self->run_info->thread_id
    })->delete;

    my $thread_row = $self->sm->table('thread')->find({
        id => +$self->run_info->thread_id
    });

    if ( $self->run_info->thread_id > +$self->settings->max_threads ) {
        $thread_row->delete;

        my $spawned_row = $self->gm->table('spawned')->find({
            process_name => 'thread',
            job_id => +$self->run_info->job_id,
            thread_id => +$self->run_info->thread_id
        });
        $spawned_row->delete if $spawned_row;
    } else {
        $thread_row->update({
            status => 'available',
            data => undef
        });
    }


}           





sub terminate{
    my ($self) = @_;

    my $logger = Log::Log4perl->get_logger;

    $self->mark_finished( $$ );
    $logger->debug("Terminating process $$ on thread ".$self->run_info->thread_id);

    Log::Log4perl->remove_logger( $logger );
    exit;
}
 

sub execute{
    my ($self,$task_data) = @_;
    my $logger = Log::Log4perl->get_logger;
    $logger->trace("Starting execute subroutine");

    return if ($self->xbranch_seen( $task_data ));


    confess "Need task_data" unless $task_data;
    my $thread_row = $self->request_process;
    $logger->trace("After request_process");
    my $xbranch;

    

    if ( $thread_row ){
        
        $xbranch = $self->utils->create_xbranch_record(
            $task_data,
            $thread_row->id
        );
        unshift @{$task_data->{xbranch_ids}}, $xbranch->id;
        $self->utils->add_run_info( $task_data );
        my $ds = $self->utils->serialize( $task_data );
        $thread_row->update({ data => $ds });
    } else {
        if ( $self->thread_is_old ){
            $logger->debug("Thread refresh time exceeded. Restarting thread");
            $self->utils->exec_xtask_script;
        } else {
            $xbranch = $self->utils->create_xbranch_record(
                $task_data,
                $self->run_info->thread_id
            );
            unshift @{$task_data->{xbranch_ids}}, $xbranch->id;
            $logger->trace("Parent executing task directly");
            $self->utils->exec_task_from_data( $task_data );
        }
    }
    $self->sm->table('xbranch')->search({
        id => +$xbranch->id
    })->update({
        status => 'seen'
    });

#    $xbranch->update({ status => 'seen' });
    $logger->trace("End of execute subroutine");

}


sub xbranch_seen{
    my ($self,$task_data) = @_;

    my $logger = Log::Log4perl->get_logger;
    $logger->trace("starting xbranch_seen subroutine");

    my $xbranch_row = $self->sm->table('xbranch')->find({
        plan_key => $task_data->{branch_id},
        input_key => $task_data->{input_id}
    }, {
        key => 'plan_key'
    });

    my $seen = 0;

    if ( $xbranch_row ){
        my $status = $xbranch_row->status;
        $seen = 1 if $status && $status eq 'seen';
    }

    $logger->debug("Already seen xbranch with plan key ".$task_data->{branch_id}." and input key ".$task_data->{input_id}) if $seen;

    $logger->trace("ending xbranch_seen subroutine");
    return $seen;
}




sub thread_is_old{
    my ($self,$thread_row) = @_;

    my $logger = Log::Log4perl->get_logger;

    my $dt = DateTime->now;

    if ( ! $thread_row ){
        $thread_row = $self->sm->table('thread')->find({
            id => $self->run_info->thread_id
        });
    }

    $logger->debug("thread_is_old: thread_id: ".$self->run_info->thread_id." job_id ".$self->run_info->job_id);

    my $thread_is_old = 0;
    if ( $thread_row ){
        $logger->debug("Got a thread row");
        my $forked_dt = $thread_row->last_forked;
        
        if ( $forked_dt ){

            $forked_dt->add( minutes => +$self->settings->refresh_mins );
            $thread_is_old = 1 if ( DateTime->compare( $dt, $forked_dt ) == 1 );
 
        }

        $thread_row->update({
            last_checked => $dt
        });

    } else {
        
        $logger->debug("No thread row");

    }

    return $thread_is_old;
}



sub start_fork{
    my ($self,$thread_id) = @_;

    my $logger = Log::Log4perl->get_logger;

    my $dt = DateTime->now;

    my $parent_pid = $$;
    $self->sm->schema->txn_do( sub{
        $self->sm->table('thread')->search({
            id => $thread_id
        })->update({
            status => 'forking',
            parent_id => +$self->run_info->thread_id,
            parent_pid => $parent_pid,
            last_forked => $dt,
            last_checked => $dt
        });
    });

    $logger->debug("Forking");
    #$self->sm->schema->storage->disconnect;
    #$self->gm->schema->storage->disconnect;

    my $pid = fork();

#    $self->sm( TaskPipe::SchemaManager->new );
#    $self->sm->connect_schema;
#    $self->gm( TaskPipe::SchemaManager->new( scope => 'global' ) );
#    $self->gm->connect_schema;

    confess "Fork failed" if not defined $pid;
    $logger->debug("Created fork $pid") if $pid;
    return $pid if $pid;
    
    $self->run_info->thread_id( $thread_id );
    $self->logger_manager->init_logger;

    $self->gm->schema->txn_do( sub{
        $self->gm->table('spawned')->update_or_create({
            process_name => 'thread',
            job_id => $self->run_info->job_id,
            used_by_pid => $parent_pid,
            thread_id => $thread_id,
            status => 'processing',
            pid => $$,
            last_checked => $dt
        });
    });

    $self->sm->table('thread')->find({
        id => $thread_id
    })->update({
        status => 'processing',
        pid => $$
    });

    $logger->debug("In child executing xtask script");
    $self->utils->exec_xtask_script;

}




sub start_forks{
    my ($self) = @_;

#    my $processing_rs = $self->sm->table('thread')->search({
#        status => 'processing'
#    });

#    return if ($processing_rs->count);

#    my $threads_rs = $self->sm->table('thread')->search({
#        status => 'ready'
#    }, {
#        rows => 1
#    });

    my $threads_rs = $self->sm->table('thread')->search({
        status => 'ready'
    });

    while ( my $thread_row = $threads_rs->next ){

        #sleep 2;
        $self->start_fork( $thread_row->id );

    }
}


sub top_up_thread_slots{
    my ($self) = @_;

    my $logger = Log::Log4perl->get_logger;

    my $taken_slots = $self->sm->table('thread')->search({},{
        order_by => 'id',
        columns => ['id']
    });

    my $max = $self->settings->max_threads;

    my $needed = $max - $taken_slots->count;

    if ( $needed > 0 ){
        my $taken_lookup = {};
        while( my $taken_slot = $taken_slots->next ){
            $taken_lookup->{ $taken_slot->id } = 1;
        }

        my $slots_to_create = [];

        my $id = 0;
        my $added = 0;

        while( $added < $needed ){
            $id++;
            
            if ( ! $taken_lookup->{$id} ){
                $self->sm->table('thread')->create({
                    id => $id,
                    status => 'available'
                });
                $added++;
            }
        }
    }
}
                



sub clean_thread_table{
    my ($self) = @_;

    my $thread_rs = $self->sm->table('thread')->search({
        status => 'processing'
    });

    while( my $thread = $thread_rs->next ){

        if ( ! pexists( $thread->pid ) ){

            $thread->update({
                status => 'available'
            });

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
