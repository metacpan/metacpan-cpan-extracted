package TaskPipe::TaskUtils;

use Moose;
use TaskPipe::Task::ModuleMap;
use Try::Tiny;
use TaskPipe::RunInfo;
use JSON;
use Data::Dumper;
use Log::Log4perl;
use Module::Runtime qw(require_module);

has sm => (is => 'rw', isa => 'TaskPipe::SchemaManager');
has gm => (is => 'rw', isa => 'TaskPipe::SchemaManager');

has run_info => (is => 'ro', isa => 'TaskPipe::RunInfo', default => sub{
    TaskPipe::RunInfo->new;
});

has json_encoder => (is => 'ro', isa => 'JSON', default => sub{
    my $json_enc = JSON->new;
    $json_enc->canonical;
    return $json_enc;
});

has settings => (is => 'ro', isa => __PACKAGE__.'::Settings', default => sub{
    my $module = __PACKAGE__.'::Settings';
    require_module( $module );
    return +$module->new;
});



sub task_from_data{
    my ($self,$data) = @_;

    my $logger = Log::Log4perl->get_logger;

    my $spec;
    if ( $data->{plan_mode} eq 'tree' ){
        $spec = $data->{plan}{task};
    } else {
        $spec = $data->{plan}[0];
    }

    my $name = $spec->{_name};
    confess "No name. spec was ".Dumper($spec)." plan was ".Dumper( $data->{plan} ) unless $name;
    confess "task spec should be a hash" unless $spec && ref($spec) =~ /hash/i;

    my $mod_map = TaskPipe::Task::ModuleMap->new(
        task_name => $name
    );
            
    my $mod_name = $mod_map->load_module;

    $logger->debug("input_id ".$data->{input_id});

    my $task = $mod_name->new(
        sm => +$self->sm,
        gm => +$self->gm,
        plan_key => $data->{plan_key},
        input_key => $data->{input_key},
        plan => $data->{plan},
        branch_id => $data->{branch_id},
        input => $data->{input},
        input_id => $data->{input_id},
        input_history => $data->{input_history},
        param => $data->{param},
        param_history => $data->{param_history},
        xbranch_ids => $data->{xbranch_ids}
    );

    return $task;
}


sub record_last_task_info{
    my ($self,$data) = @_;

    my $spec;
    if ( $data->{plan_mode} eq 'tree' ){
        $spec = $data->{plan}{task};
    } else {
        $spec = $data->{plan}[0];
    }

    my $thread_row = $self->sm->table('thread')->find({
        id => $self->run_info->thread_id
    });

    my $details = +$spec->{_name};
    if ( $spec->{_name} eq 'Record' ){
        $details.=": ".$spec->{table};
    }

    if ( $thread_row ){
        $thread_row->update({
            last_task => $details
        });
    }
}
                


sub create_xbranch_record{
    my ($self,$task_data,$thread_id,$status) = @_;

    my $logger = Log::Log4perl->get_logger;

    my $parent_xbranch_id = undef;
    $parent_xbranch_id = $task_data->{xbranch_ids}->[0] if defined $task_data->{xbranch_ids}->[0];

    my $xbranch;

    do {
        eval{

            $xbranch = $self->sm->table('xbranch')->find_or_create({
                plan_key => $task_data->{plan_key},
                input_key => $task_data->{input_key},
                thread_id => $thread_id,
                branch_id => $task_data->{branch_id},
                input_id => $task_data->{input_id},
                parent_id => $parent_xbranch_id,
                status => $status
            },
            {key => 'plan_key'});
        };

#    } while ($@);
    } while ($@ && $@ =~ /duplicate\sentry/i);

    confess $@ if $@;

    return $xbranch;
}





sub exec_task_from_data{
    my ($self,$data) = @_;

    $self->record_last_task_info( $data );
    my $task = $self->task_from_data( $data );

    try { 
        $task->execute; 
    } catch {
        $task->handle_error($_);
    };

    return $task;
}



sub serialize{
    my ($self,$ref) = @_;

    my $serialized;

    try {
        $serialized = $self->json_encoder->encode( $ref );
    } catch {
        confess "Serialize error: $_\nref was ".Dumper( $ref );
    };

    return $serialized;
}



sub deserialize{
    my ($self,$json) = @_;

    my $ref;

    try {
        $ref = $self->json_encoder->decode( $json );
    } catch {
        confess "Error deserialising json string '$json': $_";
    };

    return $ref;
}




sub exec_xtask_script{
    my ($self,$data) = @_;

#    $self->write_task_data( $data ) if $data;

    my $cmd = $self->settings->xtask_script." ".$self->run_info->job_id." ".$self->run_info->thread_id." ".$self->run_info->root_dir;
#    my $cmd = "/root/taskpipe/scratch/taskpipe-xtask.pl ".$self->run_info->job_id." ".$self->run_info->thread_id." ".$self->run_info->root_dir;

    $self->sm->schema->storage->disconnect;
    $self->gm->schema->storage->disconnect;

    exec( $cmd );
    exit;
}



#sub write_xtask_data{
#    my ($self,$data,$thread_row) = @_;

##    confess "Need data and thread_id" unless $data && $thread_id;

#    my $ds = $self->serialize( $data );

##    my $thread_row = $self->gm->table('thread')->find({
##        job_id => +$self->run_info->job_id,
##        id => $thread_id
##    });

#    confess "No thread row" unless $thread_row;

#    $thread_row->update({
#        data => $ds
#    });
#    
#}



sub add_run_info{
    my ($self,$data) = @_;

    $data->{run_info} = {};
    my @methods = $self->run_info->meta->get_all_methods;

    my @names = ();
    foreach my $method ( @methods ){
        my $name = $method->name;
        if ( ref( $method ) =~ /Accessor/ ){
            $data->{run_info}->{ $name } = $self->run_info->$name
        }
    }

#    $data->{thread_id} = $thread_id if $thread_id;

}



sub record_resume_info{
    my ($self,$xbranch_id,$input_index,$plan_index,$last_result) = @_;

    confess "No xbranch_id" unless $xbranch_id;

    my $logger = Log::Log4perl->get_logger;

    $logger->debug("Recording resume info: xid $xbranch_id, ii $input_index, pi $plan_index, last_result ".Dumper( $last_result ) );

    my $xbranch = $self->sm->table('xbranch')->find({
        id => $xbranch_id
    });

    if ( $xbranch ){
        my $err;
        try{

            $xbranch->update({
                last_plan_index => $plan_index,
                last_input_index => $input_index,
                last_result => +$self->serialize($last_result)
            });

        } catch {

            confess "Database error: $_";

        };

    }
   
}



1;
