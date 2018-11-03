package TaskPipe::Plan;

use Moose;
use File::Spec;
use Data::Dumper;
use TaskPipe::Task;
use TaskPipe::PathSettings;
use TaskPipe::Plan::Settings;
with 'MooseX::ConfigCascade';
with 'TaskPipe::Role::MooseType_PlanMode';

has settings => (is => 'rw', isa => __PACKAGE__.'::Settings', default => sub{
    my $module = __PACKAGE__.'::Settings';
    $module->new;
});
has path_settings => (is => 'rw', isa => 'TaskPipe::PathSettings', default => sub{
    TaskPipe::PathSettings->new;
});
has filename => (is => 'rw', isa => 'Str');
has content => (is => 'rw', isa => 'HashRef|ArrayRef');
has mode => (is => 'rw', isa => 'PlanMode', default => 'tree');
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
has task => (is => 'rw', isa => 'TaskPipe::Task', lazy => 1, default => sub{
    TaskPipe::Task->new(
        sm => $_[0]->sm,
        gm => $_[0]->gm
    );
});


sub run{
    my $self = shift;

    $self->load_content;
    $self->task->plan( $self->content );
    $self->task->execute;

}


sub load_content{
    my $self = shift;

    my $logger = Log::Log4perl->get_logger;

    my $filename = $self->filename || $self->path_settings->project->plan;

    my $path = $self->path_settings->path('plan',$filename);
    $logger->debug("Path to plan file: $path");

    $self->content( $self->cascade_util->parser->( $path ) );
}

=head1 NAME

TaskPipe::Plan - manage plan files for TaskPipe

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
