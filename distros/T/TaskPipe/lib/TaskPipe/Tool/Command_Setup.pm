package TaskPipe::Tool::Command_Setup;

use Moose;
use TaskPipe::PodReader;
use TaskPipe::FileInstaller;
use TaskPipe::PathSettings::Global;
use File::Inplace;
use Try::Tiny;
use File::Save::Home;
use Module::Runtime 'require_module';
extends 'TaskPipe::Tool::Command';

has option_specs => (is => 'ro', isa => 'ArrayRef', default => sub{[{
    module => 'TaskPipe::PathSettings::Global',
    items => [
        'home_filename',
        'root_dir',
        'project_dir',
        'global_dir',
        'global_conf_dir',
        'global_lib_dir',
        'global_templates_dir',
        'global_conf_filename',
        'system_conf_filename'
    ],
    section => 'METHODS',
    is_config => 0
}]});

has job_manager => (is => 'ro', isa => 'TaskPipe::JobManager', lazy => 1, default  => sub{
    TaskPipe::JobManager->new(
        name => $_[0]->name,
        project => '*global',
        shell => 'foreground'
    );
});

has pod_reader => (is => 'ro', isa => 'TaskPipe::PodReader', default => sub{
    TaskPipe::PodReader->new;
});

has template_names => (is => 'ro', isa => 'ArrayRef', default => sub{[
    'Config_Global',
    'Config_System'
]});

has file_installer => (is => 'rw', isa => 'TaskPipe::FileInstaller', lazy => 1, default => sub{
    my ($self) = @_;

    TaskPipe::FileInstaller->new(
        on_rollback => sub{
            if ( $self->home_filename_changed ){
                $self->change_home_filename( $self->existing_home_filename );
            }
        }
    );
});

has replacement_line => (is => 'ro', isa => 'Str', lazy => 1, default => sub{
    return "has <param> => (is => 'ro', isa => 'Str', default => '<default>');";
});

has home_filename_changed => (is => 'rw', isa => 'Bool', default => 0);


has ps => (is => 'ro', isa => 'TaskPipe::PathSettings::Global', default => sub{
    TaskPipe::PathSettings::Global->new;
});


has existing_home_filename => (is => 'rw', isa => 'Str', lazy => 1, default => sub{
    my ($self) = @_;
    my $conf = MooseX::ConfigCascade::Util->conf;
    MooseX::ConfigCascade::Util->conf({});
    my $ps = TaskPipe::PathSettings::Global->new;
    MooseX::ConfigCascade::Util->conf($conf);
    return +$ps->home_filename;
});


sub execute{
    my ($self) = @_;

    $self->run_info->scope('global');

    try {

        if ( $self->ps->home_filename ne $self->existing_home_filename ){
            $self->change_home_filename( $self->ps->home_filename );
            $self->home_filename_changed( 1 );
        }

        my $home_fp = $self->path_settings->home_filepath;
        if ( -f $home_fp ){

            $self->pod_reader->message( qq|=pod

    The file $home_fp already seems to exist on your system. Did you set up TaskPipe already? If you are sure TaskPipe has not already been set up, or you need a fresh install, you should delete this file.

    If this file exists because some other process created it, you will need to change the default filename which TaskPipe looks for in your home directory. You can do this by including the C<--home_filename> parameter on the command line:

        taskpipe --home_filename=.new_taskpipe_home_file

    Note that the C<--home_filename> parameter B<will change this filename system wide>. ie B<all users> will be affected by the change, so use with caution.

    =cut|);
            exit;

        }

        confess "root_dir parameter needs to be specified" unless $self->ps->root_dir;

        $self->file_installer->create_dir( $self->ps->root_dir );
        $self->file_installer->create_file( $home_fp, $self->ps->root_dir );

        foreach my $dir ( qw(project_dir global_dir) ){
            my $path = File::Spec->catdir( $self->ps->root_dir, $self->ps->$dir );
            $self->file_installer->create_dir( $path );
        }
        foreach my $dir ( qw(lib conf log) ){
            my $method = 'global_'.$dir.'_dir';

            my $path = File::Spec->catdir(
                $self->ps->root_dir,
                $self->ps->global_dir,
                $self->ps->$method
            );
            $self->file_installer->create_dir( $path );
        }

        foreach my $template_name ( @{$self->template_names} ){
            my $module = 'TaskPipe::Template_'.$template_name;
            require_module( $module );
            my $template = $module->new;
            $template->deploy;
            unshift @{$self->file_installer->files_created}, +$template->target_path;
        }
    
    } catch {

        $self->file_installer->rollback;
        confess "Rolled back changes: ".$_;

    }
}


sub change_home_filename{
    my ($self,$fn) = @_;

    my $editor = new File::Inplace( file => +$self->ps->module_path );

    while ( my ($line) = $editor->next_line ){

        my $search_for = "has home_filename";
        if ( $line =~ /^$search_for/ ){
            my $replacement = $self->replacement_line;
            $replacement =~ s/<param>/home_filename/;
            $replacement =~ s/<default>/$fn/;
            $editor->replace_line( $replacement );
        }
    }

    $editor->commit;
}



=head1 NAME

TaskPipe::Tool::Command_Setup - the TaskPipe setup command

=head1 PURPOSE

Setup is intended to be run once immediately after running package install (ie after installing the modules with C<cpan>, C<cpanm> or manually with C<make>). Setup creates the directories TaskPipe will use to store projects, and deploys the global configuration files.


=head1 DESCRIPTION

You need to specify a value for C<root_dir> at a minimum, e.g.:

    taskpipe setup --root_dir=/home/myusername/taskpipe

Subdirectories can also be specified on the command line, but will take defaults otherwise. (See options section below for default values)

You can also use setup to regenerate global directories and/or default global config files if you want to change overall directory structure or reset the global config files to factory defaults. Use with caution. Setup will I<not> overwrite files or directories that already exist - it will ignore them. So you should delete the directories/files you want to regenerate prior to running setup.

=head2 GENERAL TASKPIPE SETUP INSTRUCTIONS

You may be looking at this help because you want to know how to setup TaskPipe in general. In fact the command C<taskpipe setup> does not completely setup TaskPipe on your system (sorry!) mainly because TaskPipe doesn't immediately know how to connect to your database. 

C<taskpipe setup> installs the skeleton directory structure and the global config file. You should run C<taskpipe setup> immediately after install, because C<taskpipe> needs to find the global config file to be able to do anything further.

A suggested workflow to achieve a full setup and working projects is as follows:

=over

=item 1. Install TaskPipe

Do this using the C<cpan> shell, C<cpanp>, C<cpanm> etc. or manually using make:

    perl Makefile.PL
    make
    make test
    make install

If you are reading this using the C<taskpipe help setup> command, you have already successfully completed this step.

=item 2. Run C<setup>

    taskpipe setup --root_dir=~/taskpipe

The C</taskpipe> subdirectory inside your B<home> directory is the suggested location to install TaskPipe and these docs will tend to assume this is your install location. However, any location where you have full read/write permissions is good.

Note that TaskPipe installs a hidden file C<.taskpipe> in your home directory which will store the path to your TaskPipe install. You need to make sure C<TaskPipe> can create this file and it remains in place and readable.

Once you have run setup, you should find the following directory structure is created

    /taskpipe
        /global
            /conf
                global.conf
            /lib
        /projects

=item 3. Set up the global database

To do this

=over

=item * 

Create the database that you are going to use for TaskPipe global tables. E.g. in MySQL

    CREATE DATABASE taskpipe_global;

=item *

Edit the global config file to tell TaskPipe which database to use.

    nano ~/taskpipe/global/conf/global.conf

Look for the section C<TaskPipe::SchemaManager::Settings_Global> and fill in C<host>, C<name> etc. for your database. Make sure the database user account you specified has full privileges to your TaskPipe global database.

=item *

Run C<deploy tables>:

    taskpipe deploy tables --scope=global

More comprehensive information on this step can be found in the help for C<deploy tables>.

=item *

Generate global database schema files. TaskPipe uses the C<DBIx::Class> ORM, and schema files need creating over each database being used. To do this, you should just be able to type:

    taskpipe generate schema --scope=global

Schema files will be generated into the global lib dir (normally C</global/lib>).

More comprehensive information on this step can be found in the help for C<generate schema>

=back


=item 4. Create your project

To do this for a new project called C<myproject>:

=over

=item *

Edit the global config file and change C<project> to C<myproject> in the section C<TaskPipe::PathSettings::Global>. This basically means you have set C<myproject> as the default project, so that you don't need to type C<--project=myproject> each time you execute a project-related TaskPipe command at the terminal.

=item *

Deploy project files:

    taskpipe deploy files

See the help for C<deploy files> for more comprehensive information on this step.

=item *

Create a database to use for this project. E.g. in MySQL:

    CREATE DATABASE myproject;

Make sure your database user account has full privileges to this database. E.g. in MySQL

    GRANT ALL PRIVILEGES ON myproject.* TO 'taskpipe_user'@'localhost';

=item *

Edit the project config file and change the database connection information (C<host>, C<name>, ...) to match the project database. (Look for the section C<TaskPipe::SchemaManager::Settings_Project> in your project config file (usually found in the C</projects/myproject/conf/project.yml> file.

=item *

Deploy the project cache tables:

    taskpipe deploy tables

See the help for C<deploy tables> for more comprehensive information on this step.

=item *

Create the project itself. A project consists of several tasks, a plan of how to execute those tasks and some database tables to store gathered data. This is the meat and potatoes of TaskPipe, and here it is up to you to be creative. See the general instructions by reading the manpage for the L<TaskPipe> module or typing

    taskpipe help taskpipe

on the command line for more information on how to create projects.

=item *

Run C<generate schema> over your project to create the project schema files

    taskpipe generate schema

See the help for C<generate schema> for more information.

=back

=item 5. Run your plan

Run your plan and gather your data:

    taskpipe run plan

See the help for C<run plan> for more information on this step.

=back

=head1 OPTIONS

=over

=item root_dir

The base directory where all TaskPipe files and subdirectories should be installed. B<This parameter is required>.

=back

=cut

has root_dir => (is => 'ro', isa => 'Str');

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

__PACKAGE__->meta->make_immutable;
1;  
