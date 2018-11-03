package TaskPipe::TestUtils::Threaded;

use Moose;
use Test::More;
use TaskPipe::PathSettings;
use TaskPipe::PathSettings::Global;

has root_dir => (is => 'ro', isa => 'Str', required => 1);

has ps_global => (is => 'ro', isa => 'TaskPipe::PathSettings::Global', lazy => 1, default => sub{
    TaskPipe::PathSettings::Global->new(
        project => 'test'
    );
});

has global_ps => (is => 'ro', isa => 'TaskPipe::PathSettings', lazy => 1, default => sub{
    TaskPipe::PathSettings->new(
        scope => 'global',
        root_dir => +$_[0]->root_dir,
        global => +$_[0]->ps_global
    );
});

has project_ps => (is => 'ro', isa => 'TaskPipe::PathSettings', lazy => 1, default => sub{
    TaskPipe::PathSettings->new(
        scope => 'project',
        root_dir => +$_[0]->root_dir,
        global => +$_[0]->ps_global
    );
});


sub skip_if_no_config{
    my ($self) = @_;

    my $global_conf_path = $self->global_ps->path('conf','global.yml');
    my $project_conf_path = $self->project_ps->path('conf','project.yml');

    if ( ! -f $global_conf_path || ! -f $project_conf_path ){
        plan skip_all => "DB info for threaded tests was not provided";
        exit;
    }
}



1;
