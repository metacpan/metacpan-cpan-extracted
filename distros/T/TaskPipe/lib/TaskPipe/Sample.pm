package TaskPipe::Sample;

use Moose;
use TryCatch;
use DBIx::Error;
use TaskPipe::RunInfo;
use TaskPipe::FileInstaller;
use TaskPipe::PathSettings;
use TaskPipe::SchemaManager;

use Module::Runtime 'require_module';
with 'TaskPipe::Role::MooseType_ScopeMode';


has run_info => (is => 'ro', isa => 'TaskPipe::RunInfo', default => sub{
    TaskPipe::RunInfo->new;
});

has file_installer => (is => 'rw', isa => 'TaskPipe::FileInstaller', lazy => 1, default => sub{
    TaskPipe::FileInstaller->new;
});

has path_settings => (is => 'rw', isa => 'TaskPipe::PathSettings', lazy => 1, default => sub{
    TaskPipe::PathSettings->new;
});

has schema_manager => (is => 'rw', isa => 'TaskPipe::SchemaManager', lazy => 1, default => sub{ TaskPipe::SchemaManager->new });


sub deploy_files{
    my ($self) = @_;

    try {
    
        $self->file_installer->create_dir( $self->path_settings->project_dir );

        foreach my $dir ( qw(lib plan source log conf) ){

            $self->file_installer->create_dir( $self->path_settings->path( $dir ) );
        }


        my $lib_dir = $self->path_settings->path( 
            'lib', 
            $self->path_settings->project->task_module_prefix
        );


        $self->file_installer->create_dir( 
            $self->path_settings->path( 
                'lib', 
                $self->path_settings->project->task_module_prefix
            )
        );

        foreach my $template_name ( @{$self->templates} ){
            my $template_module = 'TaskPipe::Template_'.$template_name;        

            require_module( $template_module );
            my $template = $template_module->new;
            $template->deploy;
            unshift @{$self->file_installer->files_created}, +$template->target_path;

       }

    } catch {

        $self->file_installer->rollback;
        confess "Rolled back changes: ".$_;

    };

}




sub deploy_tables{
    my ($self) = @_;

    my @template_names = @{$self->schema_templates};
    my $first_template_name = shift @template_names;
    $self->deploy_tables_from_schema_template( $first_template_name );    
    
    return if $self->run_info->scope eq 'global'; # we only expect 1 schema to
                                        # deploy for global tables
    
    #for project templates, everything after the first template
    # is a plan template (usually only one?)

    foreach my $template_name ( @template_names ){ 
                                                
        $self->deploy_tables_from_schema_template( $template_name, 'no_prefix' );
    }
}



sub deploy_tables_from_schema_template{
    my ($self,$template_name, $no_prefix) = @_;

    my $module = 'TaskPipe::SchemaTemplate_'.$template_name;    
    my $schema = $self->schema_manager->connect_schema($module);
    my @sn = $schema->sources;

    my $table_prefix = '';
    $table_prefix = $self->schema_manager->settings->table_prefix unless $no_prefix;

    my $str = '';
    foreach my $sn (@sn){
        my $source = $schema->source( $sn );
        my $table_name = $table_prefix.$source->name;
        $source->name( $table_name );

        my $table_exists = 1;
        my $err;
        try {
            my $count = $schema->resultset( $sn )->count;
        } catch ( DBIx::Error $err where { $_->state eq "42S02" }){
            $table_exists = 0;
        };
        if ( $table_exists ){
            confess +$self->_table_exists_message($table_name);
        }
    }

    $schema->deploy;
}


sub _table_exists_message{
    my ($self,$table_name) = @_;

    my $msg = "[B<Table $table_name appears to exist already. Have you already deployed ".$self->run_info->scope." tables";
    if ($self->run_info->scope eq 'project'){
        $msg.=" for project ".$self->path_settings->global->project;
    }
    $msg.="?>]";

    return $msg;
}


=head1 NAME

TaskPipe::Sample - base class for sample projects

=head1 DESCRIPTION

When creating sample projects for taskpipe, inherit from this class

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

1;
