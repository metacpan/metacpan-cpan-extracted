package TaskPipe::Task;

our $VERSION = 0.06;

use Moose;
use Module::Runtime qw(require_module);
use Data::Dumper;
use Carp;
use Encode qw(encode);
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
use TaskPipe::TaskUtils;
use TryCatch;
use Clone 'clone';

with 'MooseX::ConfigCascade';

has sm => (is => 'rw', isa => 'TaskPipe::SchemaManager', default => sub{
    my $sm = TaskPipe::SchemaManager->new( scope => 'project' );
    $sm->connect_schema;
    return $sm;
});
has gm => (is => 'rw', isa => 'TaskPipe::SchemaManager', default => sub{
    my $gm = TaskPipe::SchemaManager->new( scope => 'global' );
    $gm->connect_schema;
    return $gm;
});

has run_info => (is => 'ro', isa => 'TaskPipe::RunInfo', default => sub{
    TaskPipe::RunInfo->new;
});

has settings => (is => 'ro', isa => 'TaskPipe::Task::Settings', default => sub{ TaskPipe::Task::Settings->new });

has utils => (is => 'ro', isa => 'TaskPipe::TaskUtils', lazy => 1, default => sub{
    TaskPipe::TaskUtils->new(
        sm => $_[0]->sm,
        gm => $_[0]->gm
    );
});


has plan => (is => 'rw', isa => 'ArrayRef|HashRef');
has plan_dd => (is => 'rw', isa => 'Str');
has plan_md5 => (is => 'rw', isa => 'Str');
has plan_key => (is => 'rw', isa => 'Str');

has input => (is => 'rw', isa => 'HashRef', default => sub{{}});
has input_dd => (is => 'rw', isa => 'Str');
has input_md5 => (is => 'rw', isa => 'Str');
has input_id => (is => 'rw', isa => 'Str');
has input_key => (is => 'rw', isa => 'Str');

has input_history => (is => 'rw', isa => 'ArrayRef', default => sub{[]});

has param => (is => 'rw', isa => 'HashRef', default => sub{{}});
has param_dd => (is => 'rw', isa => 'Str');
#has param_md5 => (is => 'rw', isa => 'Str');
has param_history => (is => 'rw', isa => 'ArrayRef', default => sub{[]});

has branch_id => (is => 'rw', isa => 'Str', default => '1-0' );
has xbranch_ids => (is => 'rw', isa => 'ArrayRef', default => sub{[]});

has pinterp => (is => 'rw', isa => 'HashRef', default => sub{{}});
has pinterp_dd => (is => 'rw', isa => 'Str');
has pinterp_md5 => (is => 'rw', isa => 'Str');


has results => (is => 'rw', isa => 'ArrayRef');
has results_pointer => (is => 'rw', isa => 'Int', default => 0);

has thread_manager => (is => 'rw', isa => 'TaskPipe::ThreadManager', lazy => 1, default => sub{
    TaskPipe::ThreadManager->new(
        gm => $_[0]->gm,
        sm => $_[0]->sm,
        utils => $_[0]->utils,
        logger_manager => $_[0]->logger_manager
    );
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
        $self->results( $results ) if $results;

        $output.= "\n\n" if $output;
        $output.= "\n";
        $output.= "=" x 60;
        $output.= "\nTesting ".ref($self).":\n\n";
        $output.= "Test Pinterp: ".Dumper( $test_pinterp )."\n\n";

        my $max = $self->settings->test_result_limit;

        for my $i (1..$max){
            my $result = $self->next_result;
            last unless $result;
            $output .= "RESULT $i:\n";
            $output .= Dumper( $result )."\n\n";
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
    my $serialized = $self->utils->serialize( $full );
    $self->input_dd( $serialized );
    $self->input_md5( md5_base64( encode("utf8",$serialized) ) );

}


sub set_param_md5{
    my ($self) = @_;

    my $full = [ $self->param, @{$self->param_history} ];
    my $serialized = $self->utils->serialize( $full );
    $self->param_dd( $serialized );
}


sub set_plan_md5{
    my ($self) = @_;

    my $serialized = $self->utils->serialize( $self->plan );
    $self->plan_dd( $serialized );
    $self->plan_md5( md5_base64( encode("utf8",$serialized) ) );
}
    


sub seen_xbranch{
    my ($self) = @_;

    my $logger = Log::Log4perl->get_logger;

    my $parent_xbranch_id = undef;
    $parent_xbranch_id = $self->xbranch_ids->[0] if defined $self->xbranch_ids->[0];

    my $xbranch;

    my $input_key;
    my $plan_key;
    if ( $self->settings->xbranch_key_mode eq 'md5' ){
        $self->set_input_md5;
        $self->set_plan_md5;
        $input_key = $self->input_md5;
        $plan_key = $self->plan_md5;
    } else {
        $input_key = $self->input_id,
        $plan_key = $self->branch_id
    }
    
    $logger->trace("Recording plan_key $plan_key input_key $input_key");

    #$self->show_xbranches("before find_or_create");


    do {
        eval{

            $xbranch = $self->sm->table('xbranch')->find_or_create({
                plan_key => $plan_key,
                input_key => $input_key,
                #param_md5 => $self->param_md5,
                branch_id => $self->branch_id,
                input_id => $self->input_id,
                parent_id => $parent_xbranch_id,        
                plan_dd => $self->plan_dd,
                input_dd => $self->input_dd,
                param_dd => $self->param_dd,
                thread_id => $self->run_info->thread_id
            },
            {key => 'plan_key'});
        };

#        if ($@ && $@ =~ /duplicate\sentry/i){

#            die "duplicate entry: $@";

#        }

    } while ($@);
#    } while ($@ && $@ =~ /duplicate\sentry/i);

    confess $@ if $@;

    unshift @{$self->xbranch_ids}, $xbranch->id;

    my $seen = 0;

    if ( $xbranch->status && $xbranch->status eq 'seen' ){
        $seen = 1;
    }

    return $seen;
}


############################# TEST ######################
sub show_xbranches{
    my ($self,$msg) = @_;
    my $logger = Log::Log4perl->get_logger;


    my $xbrancheschk = $self->sm->table('xbranch')->search({});
    my $chk = '';
    while( my $xbranchchk = $xbrancheschk->next ){
        $chk.=$self->utils->serialize( { $xbranchchk->get_columns })."\n";
    }
    $logger->trace("xbranches $msg:\n$chk");    

}
#########################################################



sub clear_xbranch_error{
    my ($self) = @_;
    $self->sm->table('xbranch_error')->search({
        xbranch_id => $self->xbranch_ids->[0]
    })->delete_all;

}




sub execute_as_task{
    my ($self) = @_;

    $self->run_info->task_name( $self->name );
    $self->run_info->task_details('');

    $self->logger_manager->init_logger;
    my $logger = Log::Log4perl->get_logger;

    $logger->trace("Starting execute_as_task subroutine");


#    if ( $self->seen_xbranch ){
#        $logger->info("Already seen xbranch ".$self->xbranch_ids->[0]." - skipping");
#        return;
#    }

#    $logger->trace("After seen_xbranch check");

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

    $logger->trace("After interp");

    $self->pinterp( $interp->interp );

#    my $results;
#    my $from_cache = 0;
#    my $should_cache = $self->settings->cache_results;
#    
#    if ( $should_cache ){
#        $results = $self->get_cached_results;
#        $from_cache = 1;
#    }
    #my $results;
    my $results = $self->get_cached_xresults;
    $logger->trace("Before action");

    $logger->debug("Plan: ".Dumper( $self->plan ));

    my $from_cache = 0;
    if ( $results ){
        $logger->debug("Results (from cache): ".Dumper( $results ));
        $from_cache = 1;
    } else {
        $results = $self->action;
        $logger->debug("Results (from actioning): ".Dumper( $results ));
    }

    $self->results( $results ) if $results;

    #$self->cache_results if $should_cache && ! $from_cache && $self->results;
    $self->cache_xresults if $results && ! $from_cache;

    #$logger->debug("After cache_results");

    my $to_pipe = $self->get_plan_to_pipe;
    $self->pipe_to( $to_pipe ) if $to_pipe;


    if ( $self->xbranch_has_error ){
        $self->set_xbranch_status( 'errors were encountered on xbranch' );
    } #else {
#        $self->mark_seen; # if ! $from_cache;
#    }

    #$self->show_xbranches("at end of task");
    $logger->trace("Ending task");

    Log::Log4perl->remove_logger( $logger );

}


sub get_cached_results{
    my ($self) = @_;

    my $logger = Log::Log4perl->get_logger;

    my $serialized = $self->utils->serialize( $self->pinterp );
    $self->pinterp_dd( $serialized );
    $self->pinterp_md5( md5_base64( encode("utf8",$serialized ) ) );

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
                push @$results, +$self->utils->deserialize( $serialized );
            }
            $logger->debug("Got cached results - pinterp id ".$cached->id);
        }
    } else {
        $logger->debug("Pinterp not cached");
    }

    return $results;
}

           

sub cache_results{
    #my ($self,$results) = @_;
    my ($self) = @_;

    my $results = $self->all_results;

    my $serialized = $self->utils->serialize( $self->pinterp );
    $self->pinterp_dd( $serialized );
    $self->pinterp_md5( md5_base64( encode("utf8",$serialized ) ) );


    my $guard = $self->sm->schema->txn_scope_guard;    
    my $pinterp = $self->sm->table('pinterp')->create({
        task_name => $self->name,
        pinterp_md5 => $self->pinterp_md5,
        pinterp_dd => $self->pinterp_dd
    });    

    foreach my $result (@$results){
        
        $self->sm->table('result')->create({
            pinterp_id => $pinterp->id,
            result => +$self->utils->serialize( $result )
        });
    }
    $guard->commit;
}



sub cache_xresults{
    my ($self) = @_;

    if ( @{$self->results} ){
        try {

            $self->sm->table('xresult')->create({
                xbranch_id => +$self->xbranch_ids->[0],
                thread_id => +$self->run_info->thread_id,
                result => +$self->utils->serialize( $self->results->[0] )
            });

        } catch ( DBIx::Error $err where { $_->state =~ /^23/ }){

            my $parent_xbranch_id = undef;
            $parent_xbranch_id = $self->xbranch_ids->[1] if @{$self->xbranch_ids} > 1;

            $self->sm->table('xbranch')->create({
                id => +$self->xbranch_ids->[0],
                plan_key => +$self->plan_key,
                input_key => +$self->input_key,
                thread_id => +$self->run_info->thread_id,
                branch_id => +$self->branch_id,
                input_id => +$self->input_id,
                parent_id => $parent_xbranch_id,
                status => undef
            });

            $self->sm->table('xresult')->create({
                xbranch_id => +$self->xbranch_ids->[0],
                thread_id => +$self->run_info->thread_id,
                result => +$self->utils->serialize( $self->results->[0] )
            });

        };
                
        for my $i (1..$#{$self->results}){
#        foreach my $result (@{$self->results}){

            my $result = $self->results->[$i];
            $self->sm->table('xresult')->create({
                xbranch_id => +$self->xbranch_ids->[0],
                thread_id => +$self->run_info->thread_id,
                result => +$self->utils->serialize( $result )
            });
        }
    }
}


sub get_cached_xresults{
    my ($self) = @_;

    my $results_rs = $self->sm->table('xresult')->search({
        xbranch_id => $self->xbranch_ids->[0]
    });

    my $results = [];        
    while( my $result_row = $results_rs->next ){
        push @$results, +$self->utils->deserialize( $result_row->result );
    }

    return undef unless @$results;
    return $results;
}            



#sub delete_cached_xresults{
#    my ($self) = @_;

#    my $results_rs = $self->sm->table('xresult')->search({
#        xbranch_id => $self->xbranch_ids->[0]
#    });

#    $results_rs->delete_all if $results_rs;
#}

    



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

    my $status = $self->thread_manager->init;

    if ( $status eq 'stop' ){
        $logger->warn("It looks like a previous completed run exists for this project, so I won't continue. If you want to start a fresh run, you should first clear the cache tables (type \"help clear tables\")");
    } else {

        if ( $status eq 'start' ){
            my $plan = clone +$self->plan;
            my $data = $self->prep_child_task_data( $plan, {},0, 0 );
            $self->thread_manager->execute( $data );
        }

        $self->thread_manager->manage;

    }
    #$self->show_xbranches("at very end");
    $logger->info("Manager: Finished run");

}





sub get_cached_pinterp{
    my ($self) = @_;
    my $logger = Log::Log4perl->get_logger;
    my $serialized = $self->utils->serialize( $self->pinterp );
    $self->pinterp_dd( $serialized );
    $self->pinterp_md5( md5_base64( encode("utf8",$serialized ) ) );

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

    my $serialized = $self->utils->serialize( $self->pinterp );
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



    
    
sub next_result{# override in child
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

    confess "next_result called in TaskPipe::Task but ->results is not defined. Did you forget to define a next_result method in your task?" unless $self->results;

    return undef if $self->results_pointer > $#{$self->results};
    my $result = $self->results->[ $self->results_pointer ];
    $self->results_pointer( $self->results_pointer + 1 );
    return $result;
}





sub count_results{
    my ($self) = @_;

    my $logger = Log::Log4perl->get_logger;

    return -1 unless $self->results;

    $logger->debug("results: ".Dumper( $self->results )) if $self->name eq 'Scrape_SearchSuggestions';

    return +scalar(@{$self->results});
}


sub reset_results{
    my ($self,$index) = @_;
    confess "reset_results called in TaskPipe::Task but ->results is not defined. Did you forget to define a count_results method in your task?" unless $self->results;

    $index ||= 0;
    $self->results_pointer( $index );
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
    
    my $ni = $self->count_results;
    
    my ($i0, $p0, $last_result ) = $self->get_resume_info;
    $logger->trace("xbranch_id ".$self->xbranch_ids->[0]." plan id ".$self->branch_id." input id ".$self->input_id." Got resume info i0 $i0 p0 $p0 last_result ".Dumper($last_result));

    my $input_item;

    my $count = 0;

    $logger->trace("Results: ".Dumper( $self->results ));

    for my $pi ($p0..$#$plan){
        $logger->trace("in loop, pi $pi");

        $self->reset_results( $i0, $last_result );
        my $ii = $i0;

        while(1){

            $input_item = $self->next_result;
            $logger->trace("input item: ".Dumper( $input_item ));
            last unless $input_item;

            $ii++;

            my $data = $self->prep_child_task_data( 
                $plan->[$pi], 
                $input_item,
                $ii,
                $pi
            );

            $tm->execute( $data );
            $self->utils->record_resume_info(
                $self->xbranch_ids->[0],
                $ii,
                $pi,
                $input_item
            );

        }

        $i0 = 0; # make sure to start inputs from scratch on the next plan iteration

    }

}



sub get_resume_info{
    my ($self) = @_;

    my $logger = Log::Log4perl->get_logger;

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

    $last_result = $self->utils->deserialize( $last_result ) if $last_result;

    #$logger->debug("GOT RESUME INFO: xid ".$self->xbranch_ids->[0]." ii $input_index pi $plan_index last_result ".Dumper( $last_result ) );
    
    return ($input_index,$plan_index,$last_result);

}


#sub execute_child_task{
#    my ($self,$plan,$input) = @_;

#    my $logger = Log::Log4perl->get_logger;

#    my $task = $self->task_from_plan($plan);

#    $task->input($input);
#    $self->add_history( $task );

#    my $param;
#    if ( $self->settings->plan_mode eq 'tree' ){
#        $task->param( clone $plan->{task} );            
#    } else {
#        $task->param( clone $plan->[0] );
#    }

#    my $err;
#    try { 
#        $task->execute; 
#    } catch( $err ) {
#        $task->handle_error($err);
#    };

#    Log::Log4perl->remove_logger( $logger );
#    $task->sm->schema->storage->disconnect;
#    $task->gm->schema->storage->disconnect;

#}



sub prep_child_task_data{
    my ($self,$plan,$input,$ii,$pi) = @_;

    my $i_current = clone $self->input;
    my $i_history = clone $self->input_history;
    unshift @$i_history, $i_current;

    my $p_current = clone $self->param;
    my $p_history = clone $self->param_history;
    unshift @$p_history, $p_current;

    my $xbranches = clone $self->xbranch_ids;

    my $param;
    if ( $self->settings->plan_mode eq 'tree' ){
        $param = clone $plan->{task};
    } else {
        $param = clone $plan->[0];
    }

    my ($branch_id) = $self->branch_id =~ /^(\d+)/;
    $branch_id++;
    $branch_id.='-'.$pi;

    my $input_id;
    if ( ! $self->input_id ){
        $input_id = $ii;
    } else {
        $input_id = $self->input_id.'-'.$ii;
    }

    my $plan_key = $branch_id;
    my $input_key = $input_id;
    if ( $self->settings->xbranch_key_mode eq 'md5' ){
        my $full = [ $input, @$i_history ];
        $input_key = md5_base64( encode("utf8",+$self->utils->serialize( $full ) ) );
        $plan_key = md5_base64( encode("utf8",+$self->utils->serialize( $plan ) ) );
    }

    return {
        plan_key => $plan_key,
        input_key => $input_key,
        plan => $plan,
        input => $input,
        ii => $ii,
        pi => $pi,
        branch_id => $branch_id,
        input_id => $input_id,
        input_history => $i_history,
        param_history => $p_history,
        xbranch_ids => $xbranches,
        param => $param,
        plan_mode => +$self->settings->plan_mode
    };
}





sub mark_seen{
    my ($self) = @_;
    
    my $logger = Log::Log4perl->get_logger;

   my $xbranch = $self->sm->table('xbranch')->search({
        id => $self->xbranch_ids->[0]
    });
    my $child_xbranches = $self->sm->table('xbranch')->search({
        parent_id => $self->xbranch_ids->[0]
    });

#    if ( $self->branch_id !~ /^2/ ){
        if ( $self->settings->seen_xbranch_policy eq 'skip' ){

            $logger->debug("Updating xbranch status to 'seen'");

            if ( $xbranch ){ 
                $xbranch->update({ status => 'seen' });
            }
        } elsif ( $self->settings->seen_xbranch_policy eq 'delete' ){
            $logger->debug("Deleting xbranch record");
        
            $xbranch->update({ status => 'seen' });

            while( my $child_xbranch = $child_xbranches->next ){
                $self->sm->table('xresult')->search({
                    xbranch_id => $child_xbranch->id
                })->delete_all;
            }
            $child_xbranches->delete_all;
            $self->sm->table('xresult')->search({
                xbranch_id => $self->xbranch_ids->[0]
            })->delete_all;

        } else {
            confess "Unrecognised seen_xbranch_policy: ".$self->settings->seen_xbranch_policy;
        }
#    }

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
        logger_manager => $self->logger_manager,
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

    my $logger = Log::Log4perl->get_logger;

    $logger->error($error_msg);

    my $guard = $self->sm->schema->txn_scope_guard;

    my $error = $self->sm->table('error')->create({
        job_id => $self->run_info->job_id,
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

    $self->thread_manager->stop_threads if $self->settings->on_task_error eq 'stop';
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
