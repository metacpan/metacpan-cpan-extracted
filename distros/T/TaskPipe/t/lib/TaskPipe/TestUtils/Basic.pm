package TaskPipe::TestUtils::Basic;

use Moose;
use Time::HiRes qw(gettimeofday tv_interval);
use Carp;
use Try::Tiny;
use TaskPipe::Tool;
use MooseX::ConfigCascade::Util;

has root_dir => (is => 'ro', isa => 'Str', required => 1);
has cmdh => (is => 'rw', isa => 'TaskPipe::Tool', default => sub{
    TaskPipe::Tool->new;
});
has gm => (is => 'rw', isa => 'TaskPipe::SchemaManager', lazy => 1, default => sub{
    my ($self) = @_;

    my $gm = TaskPipe::SchemaManager->new( scope => 'global' );
    $gm->connect_schema;
    return $gm;
});

sub stop_job{
    my ($self,$pid) = @_;

    my $job_row = $self->gm->table('job')->find({
        pid => $pid
    });

    if ( $job_row ){
        try {
            $self->taskpipe(["stop","job","--job_tracking","none","--job_id",$job_row->id]);
        } catch {
            if ( $_ !~ /Unable to find an active job/ ){
                die "Stop job failed: $_";
            }
        };
    }
}


sub clear_tables{
    my ($self) = @_;

    $self->taskpipe(["clear","tables", "--job_tracking","none","--group" => "project"]);
}


sub prep_taskpipe{
    my ($self,$cmd) = @_;

    @ARGV = @$cmd;

    push @ARGV,"--root_dir=".$self->root_dir,"--project=test";
    $self->cmdh( TaskPipe::Tool->new );
    $self->cmdh->options->add_specs([{
        module => 'TaskPipe::JobManager::Settings',
        is_config => 1
    }]);
    $self->cmdh->get_cmd;
    $self->cmdh->get_conf;
    $self->cmdh->prep_run_cmd;
}


sub taskpipe{
    my ($self,$cmd) = @_;
    $self->prep_taskpipe( $cmd );
    $self->cmdh->exec_run_cmd;
}


sub deploy_tables_unless_exist{
    my ($self) = @_;

    eval{
        $self->taskpipe(["deploy","tables","--scope","global","--job_tracking","none"]);
    };
    
    die $@ if $@ && $@ !~ /appears to exist already/;

    eval{
        $self->taskpipe(["deploy","tables","--scope","project","--project","test","--sample","test","--job_tracking","none"]);
    };
    
    die $@ if $@ && $@ !~ /appears to exist already/;
}        




sub run_plan{
    my ($self,$p) = @_;
    my %p = %$p;

    my @plan_opts = $p{plan_opts}?@{$p{plan_opts}}:();

    if ( $p{plan} ){
        if ( ref $p{plan} eq ref '' ){
            $self->prep_taskpipe(['run','plan','--plan',$p{plan},@plan_opts]);
            $self->cmdh->handler->plan->load_content;
            $self->cmdh->handler->plan->task->plan( $self->cmdh->handler->plan->content );
        } else {
            $self->prep_taskpipe(['run','plan','--project','test',@plan_opts]);
            $self->cmdh->handler->plan->content( $p{plan} );
            $self->cmdh->handler->plan->task->plan( $p{plan} );
        }
    } else {
        $self->prep_taskpipe(["run","plan",@plan_opts]);
    }

    if ( $p{threads} ){
        MooseX::ConfigCascade::Util->conf->{'TaskPipe::ThreadManager::Settings'}{max_threads} = $p{threads};
    }

    if ( $p{key_mode} ){
        MooseX::ConfigCascade::Util->conf->{'TaskPipe::Task::Settings'}{'xbranch_key_mode'} = $p{key_mode};
    }
    
    MooseX::ConfigCascade::Util->conf->{'TaskPipe::TaskUtils::Settings'}{'xtask_script'} = 'scripts/taskpipe-xtask';

    $self->cmdh->handler->job_manager->init_job;

    my $t0 = [gettimeofday];
    $self->cmdh->handler->plan->task->execute;
    my $tot_run_time = tv_interval( $t0, [gettimeofday] );
    $self->cmdh->handler->job_manager->end_job;   
    return $tot_run_time;
}



__PACKAGE__->meta->make_immutable;
1;
