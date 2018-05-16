package TaskPipe::Tool::Command_DeployTables;

use Moose;
#use Moose::Util::TypeConstraints;
#use TryCatch;
use Module::Runtime 'require_module';
use TaskPipe::Sample;
extends 'TaskPipe::Tool::Command';
with 'MooseX::ConfigCascade';
#with 'TaskPipe::Role::MooseType_ScopeMode';

has option_specs => (is => 'ro', isa => 'ArrayRef', lazy => 1, default => sub{[{
    module => 'TaskPipe::PathSettings::Global',
    is_config => 1
}, {
    module => __PACKAGE__,
    is_config => 0
}, 
{
    module => 'TaskPipe::SchemaManager::Settings_'.ucfirst($_[0]->scope),
    is_config => 1
}
]});



sub execute{
    my ($self) = @_;

    $self->run_info->scope( $self->scope );

    if ( $self->scope eq 'global' ){

        my $sample = TaskPipe::Sample->new( scope => 'global' );
        $sample->deploy_tables_from_schema_template( 'Global' );
    
    } else {

        my $module = 'TaskPipe::Sample_'.ucfirst($self->sample);
        require_module( $module );

        my $sample = $module->new;
        $sample->deploy_tables;

    }       
}




=head1 NAME

TaskPipe::Tool::Command_DeployTables - command to deploy taskpipe tables

=head1 PURPOSE

Deploy the database tables which are needed by taskpipe to operate - ie taskpipe C<global> tables or C<cache> tables for an individual project.

=head1 DESCRIPTION

If you are installing taskpipe from scratch, then you need to deploy B<global> tables, which have shared usage between taskpipe processes. Ideally you should deploy these tables to a specific designated database, which B<only> contains these global taskpipe tables. (Perhaps call this database C<taskpipe> or C<taskpipe_global> etc.) It B<is> possible to have taskpipe global tables sit alongside other tables in the same database, but not recommended (use the C<table_prefix> option to differentiate taskpipe related tables).

Running a taskpipe plan always involves using two databases - the global database (as above) and a database specfic to your project (the I<project database>). Your project database will contain 2 groups of tables, I<cache> and I<plan> tables. The I<plan> tables are tables specific to your project - so taskpipe cannot create these for you (sorry!). So deploying C<project> tables really means cache tables will be deployed to your designated project database.

=head2 Global Database

TaskPipe uses a global database to manage jobs, threads and other information. You should run C<deploy tables> once with C<--scope=global> after running C<setup>, to deploy global tables.

Make sure you have

=over

=item *

Created the database where the tables will be deployed. In MySQL:

    CREATE DATABASE taskpipe_global;

=item *

Created a user and password for taskpipe to use to access your database, and given correct access permissions for taskpipe to interface with your database.

In MySQL:

    CREATE USER 'taskpipe_user'@'localhost' IDENTIFIED BY 'somecomplexpassword';
    GRANT ALL PRIVILEGES ON taskpipe_global.* TO 'taskpipe_user'@'localhost';

=item *

Filled in the information about your database (database name, host, username, password) in the global configuration file (usually C<global.yml>, found inside C</global/conf> in your taskpipe directory). If you setup taskpipe in C</taskpipe> in your home directory, then you can modify this with a text editor. E.g. using C<nano>:

    nano ~/taskpipe/global/conf/global.yml

Look for the C<TaskPipe::SchemaManager::Settings_Global> section and change the values to suit your setup:

    ...    
    
    TaskPipe::SchemaManager::Settings_Global:
      host: localhost
      method: dbi
      module: TaskPipe::GlobalSchema
      name: taskpipe
      password: somecomplexpassword
      table_prefix: ''
      type: mysql
      username: taskpipe_user

    ...

Note that C<module> is the module taskpipe will use as a template for your tables. It is not recommended you change this.

=back

C<deploy tables> will deploy all tables with names that start with whatever you specify in C<table_prefix>. It is recommended that you don't use the global database for any other purpose (ie you simply set it up and then leave it alone). In this case, the table prefix is not important, and you can leave it as an empty string (as above).

Once you have saved the global config file with the new settings, run <deploy tables>

    taskpipe deploy tables --scope=global

You should then generate the schema files taskpipe will use to interface with the new tables

    taskpipe generate schema --scope=global

See the help for C<generate schema> for more information. For more information on C<setup> run:

    taskpipe help setup

=head2 Project Database

C<deploy tables> needs to be run each time you create a new project. First deploy the files associated with the project

    taskpipe deploy files --project=newproject

Next edit the project config that was created. If you used default directory settings, and you installed taskpipe into C<~/taskpipe> then you should find this file at C<~/taskpipe/projects/newproject/conf/project.yml> (remembering to change newproject to whatever name you called your project).

    nano ~/taskpipe/projects/newproject/conf/project.yml

Find the section C<TaskPipe::SchemaManager::Settings_Project> and edit to suit your setup

    TaskPipe::SchemaManager::Settings_Project:
      host: localhost
      method: dbi
      module: TaskPipe::Schema
      name: newproject
      password: somecomplexpassword
      table_prefix: tp_
      type: mysql
      username: taskpipe_user

Remember the table prefix will differentiate C<cache> tables (which C<deploy tables> creates) from C<plan> tables (which you will create yourself as part of your project).

Create the database you are going to use for the project. E.g. in MySQL

    CREATE DATABASE newproject;

and make sure your taskpipe user has permissions to the new database. E.g. in MySQL

    GRANT ALL PRIVILEGES ON newproject.* TO 'taskpipe_user'@'localhost';

Then run C<deploy tables>

    taskpipe deploy tables --project=newproject

You should now be ready to start building your project.


=head1 OPTIONS

=over

=item scope

Either C<global> or C<project> (deploys cache tables only).

=cut

has scope => (is => 'ro', isa => 'ScopeMode', default => 'project');


=item sample

The name of the sample to use to deploy tables. This is only relevant when C<scope> is C<project>. When C<scope> is C<global> this will be ignored.

=back

=cut

has sample => (is => 'ro', isa => 'Str', default => 'stubs');

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

__PACKAGE__->meta->make_immutable;
1;    


