package TaskPipe::Task;

our $VERSION = 0.05;

use Moose;
use Module::Runtime qw(require_module);
use Data::Dumper;
use Carp;
use Digest::MD5 qw(md5_base64);
use Log::Log4perl;
use DateTime;
use TaskPipe::Task::Settings;
use TaskPipe::Task::ModuleMap;
use MooseX::ClassAttribute;
use TaskPipe::InterpParam;
use TaskPipe::LoggerManager;
use JSON;
use TaskPipe::ThreadManager;
use TaskPipe::Iterator_Array;
use TaskPipe::RunInfo;
use Try::Tiny;
use Clone 'clone';
with 'MooseX::ConfigCascade';

has sm => (is => 'ro', isa => 'TaskPipe::SchemaManager', required => 1);
has gm => (is => 'ro', isa => 'TaskPipe::SchemaManager', required => 1);

has run_info => (is => 'ro', isa => 'TaskPipe::RunInfo', default => sub{
    TaskPipe::RunInfo->new;
});

has settings => (is => 'ro', isa => 'TaskPipe::Task::Settings', default => sub{ TaskPipe::Task::Settings->new });

has counter => (is => 'rw', isa => 'Int');

has plan => (is => 'rw', isa => 'ArrayRef|HashRef');
has plan_dd => (is => 'rw', isa => 'Str');
has plan_md5 => (is => 'rw', isa => 'Str');

has input => (is => 'rw', isa => 'HashRef', default => sub{{}});
has input_dd => (is => 'rw', isa => 'Str');
has input_md5 => (is => 'rw', isa => 'Str');
has input_history => (is => 'rw', isa => 'ArrayRef', default => sub{[]});

has param => (is => 'rw', isa => 'HashRef', default => sub{{}});
has param_dd => (is => 'rw', isa => 'Str');
has param_md5 => (is => 'rw', isa => 'Str');
has param_history => (is => 'rw', isa => 'ArrayRef', default => sub{[]});


has xbranch_ids => (is => 'rw', isa => 'ArrayRef', default => sub{[]});

has pinterp => (is => 'rw', isa => 'HashRef', default => sub{{}});
has pinterp_dd => (is => 'rw', isa => 'Str');
has pinterp_md5 => (is => 'rw', isa => 'Str');

has results_iterator => (is => 'rw', isa => 'TaskPipe::Iterator');

has thread_manager => (is => 'rw', isa => 'TaskPipe::ThreadManager', lazy => 1, default => sub{
    TaskPipe::ThreadManager->new(
        gm => $_[0]->gm,
        max_threads => $_[0]->settings->threads
    );
});

has json_encoder => (is => 'ro', isa => 'JSON', default => sub{
    my $json_enc = JSON->new;
    $json_enc->canonical;
    return $json_enc;
});

has logger_manager => (is => 'ro', isa => 'TaskPipe::LoggerManager', default => sub{
    TaskPipe::LoggerManager->new;
});

####### Attributes related to testing #############
has test_label => (                  
    is => 'ro',                      
    isa => 'Str'                   
);                                  

has test_pinterp => (               # override to make
    is => 'ro',                     # task testable
    isa => 'ArrayRef[HashRef]',     #
    default => sub{[{}]}            #
);
has test_settings => (
    is => 'ro', 
    isa => __PACKAGE__.'::TestSettings',
    lazy => 1,
    default => sub {
        my $module = __PACKAGE__.'::TestSettings';
        require_module( $module );
        $module->new;
    }
);
###################################################


sub name{ my ($n) = ref($_[0]) =~ /^${\__PACKAGE__}_(\w+)$/; $n; }


sub test{
    my ($self) = @_;

    my $logger = Log::Log4perl->get_logger;

    my $output = "";

    foreach my $test_pinterp ( @{$self->test_data} ){

        $self->pinterp( $test_pinterp );
        my $results = $self->action;

        $output.= "\n\n" if $output;
        $output.= "\n";
        $output.= "=" x 60;
        $output.= "\nTesting ".ref($self).":\n\n";
        $output.= "Test Pinterp: ".Dumper( $test_pinterp )."\n\n";

        if ( ref $results eq 'TaskPipe::Iterator' ){
            $output.="Task returned an iterator. Showing first 10 results\n\n";
            for my $i (1..10){
                my $result = $results->next->();
                $output .= "RESULT $i:\n";
                $output .= Dumper( $result )."\n\n";
            }
        } else {
            $output.= "Results: ".Dumper( $results )."\n\n";
        }

    }
    $output.= $self->add_test_output if $self->can('add_test_output');
    $output.= "=" x 60;

    $logger->info( $output );

}






sub test_data{
    my ($self) = @_;

    my $logger = Log::Log4perl->get_logger;
    my $pinterp = $self->test_pinterp;
    
    if ( ! $pinterp ){
        $logger->warn("No test_pinterp defined. Assuming this task does not need it");
        return [{}];
    }

    if ( ! @$pinterp ){
        $logger->warn("test_pinterp defined but empty. Attempting to proceed without test data");
        return [{}]
    }

    if ( ref $pinterp eq ref [] ){
        if ( $self->test_label ){
            confess "test data is labelled by numeric index, but label supplied (".$self->test_label.") was not numeric" unless $self->test_label =~ /^\d+$/; 
            my $di = $pinterp->[ $self->test_label ];            
            confess "No data found at test index ".$self->test_label unless defined $di;
            return [ $di ];
        } else {
            return $pinterp;
        }
    } elsif( ref $pinterp eq ref {} ){
        if ( $self->test_label ){
            my $di = $pinterp->{ $self->test_label };
            confess "Could not find a test named ".$self->test_label unless defined $di;
            return [ $di ];
        } else {
            return +values %$pinterp;
        }
    }
}   


sub execute{
    my ($self) = @_;

    if ( $self->is_manager ){

        $self->execute_as_manager;

    } else {

        $self->execute_as_task;

    }

}



sub set_input_md5{
    my ($self) = @_;

    my $full = [ $self->input, @{$self->input_history} ];
    my $serialized = $self->serialize( $full );
    $self->input_dd( $serialized );
    $self->input_md5( md5_base64( $serialized ) );

}


sub set_param_md5{
    my ($self) = @_;

    my $full = [ $self->param, @{$self->param_history} ];
    my $serialized = $self->serialize( $full );
    $self->param_dd( $serialized );
    $self->param_md5( md5_base64( $serialized ) );
}


sub set_plan_md5{
    my ($self) = @_;

    my $serialized = $self->serialize( $self->plan );
    $self->plan_dd( $serialized );
    $self->plan_md5( md5_base64( $serialized ) );
}



sub seen_xbranch{
    my ($self) = @_;

    my $logger = Log::Log4perl->get_logger;

    my $parent_xbranch_id = undef;
    $parent_xbranch_id = $self->xbranch_ids->[0] if defined $self->xbranch_ids->[0];

    my $xbranch;
    do {
        eval{

            $xbranch = $self->sm->table('xbranch')->find_or_create({
                plan_md5 => $self->plan_md5,
                input_md5 => $self->input_md5,
                param_md5 => $self->param_md5,
                parent_id => $parent_xbranch_id,        
                plan_dd => $self->plan_dd,
                input_dd => $self->input_dd,
                param_dd => $self->param_dd,
                thread_id => $self->run_info->thread_id
            },
            {key => 'plan_md5'});
        }
    } while ($@ && $@ =~ /duplicate\sentry/i);

    confess $@ if $@;

    unshift @{$self->xbranch_ids}, $xbranch->id;

    my $seen = 0;

    if ( $xbranch->status && $xbranch->status eq 'seen' ){
        $logger->debug("Current inputs ".$self->input_dd." Seen inputs ".$xbranch->input_dd);
        $seen = 1;
    }

    return $seen;
}



sub clear_xbranch_error{
    my ($self) = @_;
    $self->sm->table('xbranch_error')->search({
        xbranch_id => $self->xbranch_ids->[0]
    })->delete_all;

}




sub execute_as_task{
    my ($self) = @_;

    $self->run_info->task_name( $self->name );
    $self->logger_manager->init_logger;
    my $logger = Log::Log4perl->get_logger;

    $self->set_input_md5;
    $self->set_param_md5;
    $self->set_plan_md5;
    

    if ( $self->seen_xbranch ){
        $logger->info("Already seen xbranch ".$self->xbranch_ids->[0]." - skipping");
        $logger->debug("BRANCH: ".$self->plan_dd);
        $logger->debug("INPUTS: ".$self->input_dd);
        return;
    }

    $self->clear_xbranch_error;

    my %to_interp = %{$self->param};
    foreach my $key (keys %to_interp){
        delete $to_interp{$key} if $key =~ /^\_/;
    }
    

    my $interp = TaskPipe::InterpParam->new(
        input => $self->input,
        input_history => $self->input_history,
        param => $self->param,
        param_history => $self->param_history
    );

    $self->pinterp( $interp->interp );

    my $results;
    my $from_cache = 0;
    my $should_cache = $self->settings->cache_results;

    if ( $should_cache ){
        $results = $self->get_cached_results;
        $from_cache = 1 if $results;
    }

    $results = $results || $self->action;
    my $is_array = ref $results eq ref [];

    if ( $should_cache && $is_array && ! $from_cache ){
        $self->cache_results( $results );
    }

    if ( $is_array ){
        $self->results_iterator( TaskPipe::Iterator_Array->new( array => $results ) );
    } elsif ( ref($results) eq 'TaskPipe::Iterator' ){
        $self->results_iterator( $results );
    } else {
        confess "Expected an arrayref, or a TaskPipe::Iterator. Instead action returned [$results]";
    }


    my $to_pipe = $self->get_plan_to_pipe;
    
    $self->pipe_to( $to_pipe ) if $to_pipe;

    if ( $self->xbranch_has_error ){
        $self->set_xbranch_status( 'errors were encountered on xbranch' );
    } else {
        $self->mark_seen;
    }

}


sub get_cached_results{
    my ($self) = @_;

    my $serialized = $self->serialize( $self->pinterp );
    $self->pinterp_dd( $serialized );
    $self->pinterp_md5( md5_base64( $serialized ) );

    my $cached = $self->sm->table('pinterp')->search({
        task_name => $self->name,
        pinterp_md5 => $self->pinterp_md5
    })->first;
    
    my $results;
    if ( $cached ){
        
        my $results_rs = $self->sm->table('result')->search({
            pinterp_id => $cached->id
        });

        if ( $results_rs ){
            $results = [];
            while( my $serialized = $results_rs->next ){
                push @$results, +$self->deserialize( $serialized );
            }
        }
    }

    return $results;
}

           

sub cache_results{
    my ($self,$results) = @_;

    my $serialized = $self->serialize( $self->pinterp );
    $self->pinterp_dd( $serialized );
    $self->pinterp_md5( md5_base64( $serialized ) );


    my $guard = $self->sm->schema->txn_scope_guard;    
    my $pinterp = $self->sm->table('pinterp')->create({
        task_name => $self->name,
        pinterp_md5 => $self->pinterp_md5,
        pinterp_dd => $self->pinterp_dd
    });    

    foreach my $result (@$results){
        
        $self->sm->table('result')->create({
            pinterp_id => $pinterp->id,
            result => +$self->serialize( $result )
        });
    }
    $guard->commit;
}



sub get_plan_to_pipe{
    my ($self) = @_;

    my $to_pipe;
    if ( $self->settings->plan_mode eq 'tree' ){
        my $orig_pipe_to = $self->plan->{pipe_to};
        if ( $orig_pipe_to ){
            my $clone = clone $orig_pipe_to;
            if ( ref( $clone ) =~ /hash/i ){
                $to_pipe = [ $clone ];
            } else {
                $to_pipe = $clone;
            }
        }
    } else {
        my $clone = clone $self->plan;
        shift @$clone;
        $to_pipe = [ $clone ] if @$clone;
    }

    return $to_pipe;

}



sub execute_as_manager{
    my ($self) = @_;
    my $logger = Log::Log4perl->get_logger;
    $logger->debug( "Executing as manager");

    confess "Cannot execute: No plan to execute was provided" unless defined $self->plan;

    if ( $self->settings->plan_mode eq 'branch' && ref($self->plan) eq ref {} ){
        confess "B<You have set> C<plan_mode=branch> B<but you appear to be attempting to pass a hash to ".__PACKAGE__." (ie it looks like your plan is in> C<tree> B<format.) Either you need to change> C<plan_mode> to C<tree>B<, or you may have a syntax error in your plan>";
    }

    confess "Cannot execute: Plan is empty" if (
            $self->settings->plan_mode eq 'tree' && ! %{$self->plan}
        ||  $self->settings->plan_mode eq 'branch' && ! @{$self->plan}
    );

    $self->thread_manager->init;
    $self->pipe_through;
    $self->thread_manager->finalize;
}





sub get_cached_pinterp{
    my ($self) = @_;
    my $logger = Log::Log4perl->get_logger;
    my $serialized = $self->serialize( $self->pinterp );
    $self->pinterp_dd( $serialized );
    $self->pinterp_md5( md5_base64( $serialized ) );

    my $cached = $self->sm->table('pinterp')->search({
        task_name => $self->name,
        pinterp_md5 => $self->pinterp_md5
    })->first;
    
    if ( ! $cached ){
        $logger->debug( "pinterp is not cached");
        $self->cached_pinterp( undef );
        return;
    }

    if ( ! $cached->status || $cached->status ne 'fully-cached'){
        $self->cached_pinterp( undef );
        return;
    }

    $logger->debug( "pinterp is cached");
    $self->cached_pinterp( $cached );
}




sub clear_partially_cached{

    my ($self,$cached) = @_;

    my $guard = $self->sm->schema->txn_scope_guard;
    my $groups = $self->sm->table('result_group')->search({
        pinterp_id => $cached->id
    });

    while( my $group = $groups->next ){
    
        my $results = $self->sm->table('result')->search({
            group_id => $group->id
        })->delete_all;

    }

    $groups->delete_all;
    $cached->delete;
    $guard->commit;
}


        
sub cache_pinterp{
    my ($self) = @_;

    my $serialized = $self->serialize( $self->pinterp );
    $self->pinterp_dd( $serialized );

    $self->pinterp_md5( md5_base64($self->pinterp_dd) );

    my $cached = $self->sm->table('pinterp')->create({
        task_name => $self->name,
        pinterp_md5 => $self->pinterp_md5,
        pinterp_dd => $self->pinterp_dd,
        status => 'partially-cached'
    });    

    $self->cached_pinterp( $cached );
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
    }

    return $ref;
}




    
    
sub next_result{
    my ($self) = @_;

    if ( $self->is_manager ){

        return +$self->next_result_as_manager;

    } else {

        return +$self->next_result_as_task;

    }
}



sub next_result_as_manager{
    my ($self) = @_;

    my %input = %{$self->input};
    $self->input({});
    return +%input?\%input:undef;
}



sub next_result_as_task{
    my ($self) = @_;

    return +$self->results_iterator->next->();
}



sub count_results{
    my ($self) = @_;

    return +$self->results_iterator->count->();
}



sub reset_results_iterator{
    my ($self,$index,$last) = @_;

    $self->results_iterator->reset->($index,$last);
}



sub is_manager{ #it's a manager if it is the root task
                #ie it doesn't have a type, so it's class
                #should be just 'Task'

    my ($self) = @_;
    return ref($self) eq __PACKAGE__?1:0;
}


sub pipe_through{
    my ($self) = @_;

    my %input = %{$self->input};
    my $plan = clone $self->plan;
    my $task = $self->task_from_plan( $plan );
    $task->input( \%input );

    if ( $self->settings->plan_mode eq 'tree' ){
        $task->param( clone $plan->{task} );
    } else {
        $task->param( clone $plan->[0] );
    }

    eval{ $task->execute };
    $task->handle_error($@) if $@;

}



sub pipe_to{
    my ($self,$plan) = @_;

    my $logger = Log::Log4perl->get_logger;

    my $tm = $self->thread_manager;
    $tm->forks(0);
    
    my $ni = $self->count_results;
    
    my ($i0, $p0, $last_result ) = $self->get_resume_info;

    for my $pi ($p0..$#$plan){

        $self->reset_results_iterator( $i0, $last_result );
        $i0 = 0; # make sure to start inputs from scratch on the next plan iteration
        $last_result = undef;
        my $ii = 0;

        my $input_item;
        my $gid;

        while(1){
            $input_item = $self->next_result;
            last unless $input_item;

            $ii++;
            my $count = $pi * $ni + $ii;
            my $last_rec_cond = $pi == $#$plan && $ii == $ni ? 1 : 0;

            $tm->execute( sub{
                    $self->execute_child_task( $plan->[$pi], $input_item );
                    $self->record_resume_info( $ii,$pi,$input_item );
                },
                $count,
                $last_rec_cond
            );
        }
    }

    $tm->wait_children;
}



sub record_resume_info{
    my ($self,$input_index,$plan_index,$last_result) = @_;

    my $xbranch = $self->sm->table('xbranch')->find({
        id => $self->xbranch_ids->[0]
    });

    if ($xbranch){
        $xbranch->update({
            last_plan_index => $plan_index,
            last_input_index => $input_index,
            last_result => +$self->serialize($last_result)
        });
    }
}



sub get_resume_info{
    my ($self) = @_;

    my $xbranch = $self->sm->table('xbranch')->find({
        id => $self->xbranch_ids->[0]
    });

    my $plan_index = 0;
    my $input_index = 0;
    my $last_result;

    if ( $xbranch ){
        $plan_index = $xbranch->last_plan_index || 0;
        $input_index = $xbranch->last_input_index || 0;
        $last_result = $xbranch->last_result || undef;
    }

    $last_result = $self->deserialize( $last_result ) if $last_result;

    return ($input_index,$plan_index,$last_result);
}






sub execute_child_task{
    my ($self,$plan,$input) = @_;

    my $logger = Log::Log4perl->get_logger;

    my $task = $self->task_from_plan($plan);
    $task->input($input);
    $self->add_history( $task );

    my $param;
    if ( $self->settings->plan_mode eq 'tree' ){
        $task->param( clone $plan->{task} );            
    } else {
        $task->param( clone $plan->[0] );
    }

    try { 
        $task->execute; 
    } catch {
        $task->handle_error($_);
    };

}



sub mark_seen{
    my ($self) = @_;
    
    my $xbranch = $self->sm->table('xbranch')->search({
        id => $self->xbranch_ids->[0]
    })->delete_all;

}



sub add_history{
    my ($self,$task) = @_;

    my $i_current = clone $self->input;
    my $i_history = clone $self->input_history;
    unshift @$i_history, $i_current;
    $task->input_history( $i_history );

    my $p_current = clone $self->param;
    my $p_history = clone $self->param_history;
    unshift @$p_history, $p_current;
    $task->param_history( $p_history );

    my $xbranches = clone $self->xbranch_ids;
    $task->xbranch_ids( $xbranches );
}



sub task_from_plan{
    my ($self,$plan) = @_;

    my $spec;
    if ( $self->settings->plan_mode eq 'tree' ){
        $spec = $plan->{task};
    } else {
        $spec = $plan->[0];
    }

    my $name = $spec->{_name};
    confess "No name. spec was ".Dumper($spec)." plan was ".Dumper( $plan ) unless $name;
    confess "task spec should be a hash" unless $spec && ref($spec) =~ /hash/i;

    my $mod_map = TaskPipe::Task::ModuleMap->new(
        task_name => $name
    );
        
    my $mod_name = $mod_map->load_module;

    my $task = $mod_name->new(
        sm => $self->sm,
        gm => $self->gm,
        thread_manager => $self->thread_manager,
        plan => $plan
    );

    return $task;

}


sub set_xbranch_status{
    my ($self,$status) = @_;

    my $xbranch = $self->sm->table('xbranch')->find({
        id => $self->xbranch_ids->[0]
    });

    if ( $xbranch ){
        $xbranch->update({
            status => $status
        });
    }
}



sub handle_error{
    my ($self,$error_msg) = @_;

    my $guard = $self->sm->schema->txn_scope_guard;

    my $error = $self->sm->table('error')->create({
        history_index => scalar( @{$self->input_history} ),
        tag => $self->param->{_tag},
        task_name => $self->name,
        input_dd => Dumper( $self->input ),
        param_dd => Dumper( $self->param ),
        pinterp_dd => Dumper( $self->pinterp ),
        xbranch_ids => join(',',@{$self->xbranch_ids}),
        thread_id => $self->run_info->thread_id,
        message => $error_msg
    });

    foreach my $xbranch_id ( @{$self->xbranch_ids} ){

        $self->sm->table('xbranch_error')->create({
            xbranch_id => $xbranch_id,
            error_id => $error->id
        });
    }
    $guard->commit;

    $self->thread_manager->finalize if $self->settings->on_task_error eq 'stop';
}



sub xbranch_has_error{
    my ($self) = @_;

    my $has_error = 0;

    my $num_errors = $self->sm->table('xbranch_error')->search({
        xbranch_id => $self->xbranch_ids->[0]
    })->count;

    $has_error = 1 if $num_errors > 0;
    return $has_error;
}




sub action{
    my ($self) = @_;

    confess "action in ".__PACKAGE__." should NOT be called. Override this method in child class";

}

=head1 NAME

TaskPipe::Task - the class which all TaskPipe tasks should inherit from

=head1 DESCRIPTION

Inherit from this class when creating new tasks. Your child task should contain an C<action> subroutine, which returns either:

=over

=item 1.

An arrayref of results

=item 2.

A L<TaskPipe::Iterator> of results. (See the L<TaskPipe::Iterator> manpage for more information

=back

You should write your task in the following format:

    package TaskPipe::Task_MyTaskName

    use Moose;
    extends 'TaskPipe::Task';

    
    sub action {
        my ($self) = @_;

        # access plan parameters in here
        # via $self->param

        my $some_val = $self->param->{some_param};

        # ... do something with $some_val ...

        # ...

        return \@results;
    }

    __PACKAGE__->meta->make_immutable;
    1;

Then you reference it in your plan via something like:

    # (in tree format):

    task:
        _name: MyTaskName
        some_param: 46

    pipe_to:

        # ...

Note that if you are creating a task to scrape a website, it is recommended to inherit from L<TaskPipe::Task_Scrape> instead of inheriting from L<TaskPipe::Task> directly. See L<TaskPipe::Task_Scrape> for more information

=head1 SEE ALSO

See the other tasks that are provided to make sure you are not creating a task that exists already:

L<TaskPipe::Task_Scrape>
L<TaskPipe::Task_Record>
L<TaskPipe::Task_SourceFromDB>
L<TaskPipe::Task_SourceFromFile>

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

__PACKAGE__->meta->make_immutable;
1;
