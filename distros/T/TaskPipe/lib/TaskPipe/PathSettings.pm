package TaskPipe::PathSettings;

use Moose;
use File::Spec;
use Carp;
use TaskPipe::PathSettings::Project;
use TaskPipe::PathSettings::Global;
use TaskPipe::RunInfo;
use File::Save::Home;
use Data::Dumper;
use File::Slurp;

with 'MooseX::ConfigCascade';
with 'TaskPipe::Role::MooseType_ScopeMode';

has run_info => (is => 'ro', isa => 'TaskPipe::RunInfo', default => sub{
    TaskPipe::RunInfo->new;
});

has scope => (is => 'rw', isa => 'ScopeMode', default => sub {
    $_[0]->run_info->scope;
});

has project => (is => 'rw', isa => 'TaskPipe::PathSettings::Project', default => sub{
    TaskPipe::PathSettings::Project->new;
});
has global => (is => 'rw', isa => 'TaskPipe::PathSettings::Global', default => sub{
    TaskPipe::PathSettings::Global->new
});
has project_name => (is => 'rw', isa => 'Str', lazy => 1, default => sub{
    return $_[0]->global->project;
});
has root_dir => (is => 'ro', isa => 'Str', lazy => 1, default => sub{
    my ($self) = @_;

    return $self->global->root_dir if +$self->global->root_dir;

    my $home_fp = $self->home_filepath;
    #open my $fh, "<", $home_fp or confess "Could not open $home_fp: $!";
    #my $root_dir = <$fh>;
    my $root_dir = read_file( $home_fp );
    $root_dir =~ s/^\s*//s;
    $root_dir =~ s/\s*$//s;

    #close $fh or die "close file $home_fp failed: $!";
    return $root_dir;
});

has _no_project_err => (is => 'ro', isa => 'Str', default => "[B<Could not determine the name of the project to use. Did you forget to include> C<--project> B<on the command line? Alternatively, specify a default project in the TaskPipe::PathSettings::Global section in your config:>

    project: myproject

]");


sub path{
    my ($self,$dir_name,@frags) = @_;

    my $path;

    if ( $self->scope eq 'global' ){
        $path = $self->_global_path($dir_name,@frags);       
    } else {
        $path = $self->_project_path($dir_name,@frags);
    }

    $path = File::Spec->catdir($path,@frags) if @frags;
    return $path;
}


sub _global_path{
    my ($self, $dir_name, @frags) = @_;

    my $method = 'global_'.$dir_name.'_dir';

    confess "A directory named '$dir_name' has not been defined" unless $self->global->can($method);
    return +File::Spec->catdir(
        $self->root_dir,
        $self->global->global_dir,
        $self->global->$method
    );
}


sub _project_path{
    my ($self, $dir_name, @frags) = @_;
    
    if ( $dir_name eq 'conf' ){

        return +$self->project_conf_dir;

    } else {

        my $method = $dir_name.'_dir';            
        confess "A directory named '$dir_name' has not been defined" unless $self->project->can($method);

        return +File::Spec->catdir(
            $self->project_dir,
            $self->project->$method
        );
    }
}
    


sub project_root{
    my ($self) = @_;

    confess "No root_dir" unless $self->root_dir;
    confess "No project_dir" unless $self->global->project_dir;

    return +File::Spec->catdir(
        $self->root_dir,
        $self->global->project_dir
    );
}



sub project_dir{
    my ($self) = @_;

    my $project_root = $self->project_root;
    confess "No project_root" unless $project_root;

    if ( ! $self->global->project ){
        confess +$self->_no_project_err;
    }

    return +File::Spec->catdir(
        $self->project_root,
        $self->global->project
    );
}




sub project_conf_dir{
    my ($self) = @_;

    confess "No project dir" unless $self->project_dir;
    confess "No conf_dir" unless $self->global->conf_dir;

    return +File::Spec->catdir(
        $self->project_dir,
        $self->global->conf_dir
    );
}



sub filename{
    my ($self,$file_label) = @_;

    my $method;
    if ( $self->scope eq 'global' ){
        $method = $file_label.'_conf_filename';
    } else {
        $method = $file_label.'_filename';
    }

    confess "Method $method not found on ".ref( $self->global ) unless $self->global->can( $method );
    return +$self->global->$method;
}


sub home_filepath{
    my ($self) = @_;

    my $home_dir = File::Save::Home::get_home_directory();
    return +File::Spec->catdir( $home_dir, $self->global->home_filename );
}

=head1 NAME

TaskPipe::PathSettings - Path settings for TaskPipe

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
__END__
