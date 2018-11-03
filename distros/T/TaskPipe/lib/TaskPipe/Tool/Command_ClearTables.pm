package TaskPipe::Tool::Command_ClearTables;

use Moose;
use MooseX::ClassAttribute;
use Moose::Util::TypeConstraints;
use TaskPipe::SchemaManager;
use TaskPipe::JobManager;
use Getopt::Long;
use TryCatch;
use Log::Log4perl;
use Data::Dumper;
use DateTime;
use DBIx::Error;
extends 'TaskPipe::Tool::Command';
with 'MooseX::ConfigCascade';
with 'TaskPipe::Role::MooseType_ScopeMode';


has option_specs => (is => 'ro', isa => 'ArrayRef', default => sub{[{
    module => __PACKAGE__,
    is_config => 0
}]});

has monikers => (is => 'rw', isa => 'ArrayRef', default => sub{[]});

has schema_manager => (is => 'rw', isa => 'TaskPipe::SchemaManager', lazy => 1, default => sub{
    my $sm = TaskPipe::SchemaManager->new;
    $sm->connect_schema;
    return $sm;
});


subtype 'TableGroup',
    as 'Str',
    where { 
            $_ eq 'cache'
        ||  $_ eq 'plan'
        ||  $_ eq 'project'
    };


sub cache_table_names{
    my $self = shift;

    my $sm = TaskPipe::SchemaManager->new;
    my $schema = $sm->connect_schema('TaskPipe::SchemaTemplate_Project');
    my @monikers = $schema->sources;

    my $cache_names = {};

    foreach my $moniker (@monikers){

        my $source = $schema->source( $moniker );
        my $table_name = $sm->settings->table_prefix.$source->name; 
        $cache_names->{ $table_name } = 1;

    }

    return $cache_names;
}



sub get_group_monikers{
    my $self = shift;

    my @all_monikers = $self->schema_manager->schema->sources;  
    
    if ( $self->scope eq 'global' || $self->group eq 'project' ){

        $self->monikers( \@all_monikers );
        return;
    }

    my @monikers = ();

    my $cache_names = $self->cache_table_names;

    foreach my $moniker (@all_monikers){
        my $source = $self->schema_manager->schema->source( $moniker );

        if ( $cache_names->{ $source->name } ){

            push @monikers, $moniker if $self->group eq 'cache';

        } else {

            push @monikers, $moniker if $self->group eq 'plan';

        }
    }

    $self->monikers( \@monikers );
}



sub filter_monikers{    # input list of monikers for group, output list
                        # filtered by tables list

    my $self = shift;

    my $filtered = [];

    foreach my $name ( @{$self->tables } ){

        my ($moniker) = grep { $self->schema->source( $_ )->name eq $name } @{$self->monikers};

        if ( $moniker ){

            push @$filtered, $moniker;

        } else {

            confess "Table '$name' not found";

        }

    }

    $self->monikers( $filtered );
}





sub execute{
    my ($self) = @_;
    
    $self->run_info->scope( $self->scope );

    my $logger = Log::Log4perl->get_logger;

    my $guard = $self->schema_manager->schema->txn_scope_guard;

    $self->get_group_monikers;
    $self->filter_monikers if $self->tables;

    my %failed;

    while( @{$self->monikers} ){

        my $moniker = pop( @{$self->monikers} );

        my $err;
        try {

            $self->schema_manager->schema->resultset( $moniker )->delete;

        } catch ( DBIx::Error $err where { $_->state =~ /^23/ }){
            unshift @{$self->monikers},$moniker;
            $failed{ $moniker } = 1;
            confess "Unable to clear tables of group '".$self->group."': Foreign key references prevent record deletion. Last error message was $err" if scalar(keys %failed) == @{$self->monikers};

        };

    }

    $guard->commit;

    if ( $self->scope eq 'global'){
        $logger->info("Successfully cleared global tables");
    } else {
        $logger->info("Successfully cleared ".$self->group." tables for project "
            .$self->schema_manager->path_settings->project_name);
    }

}

=head1 NAME

TaskPipe::Tool::Command_ClearTables - command to clear tables

=head1 PURPOSE

A convenience function for clearing a group of tables in the database.

=head1 DESCRIPTION

The C<clear tables> command is intended for use in early development when mistakes are frequent and it is desirable to run plans over an empty database each time. The default behaviour is to clear only the C<cache> tables. You can clear only C<plan> tables by specifying C<--group=plan> or both C<cache> and C<plan> tables (ie the whole project) using C<--group=project>. Note that clearing all tables in the project would mean e.g. any source tables you were using would also be emptied. Be careful! The default is set for a reason...

It is also possible to clear C<global> tables (instead of project specific tables) by specifying C<--scope=global> (if you do so, the C<--group> parameter will be ignored). However, this should not normally be necessary. Use with caution and only if you understand the consequences.

=head1 OPTIONS

=over

=item group

Use C<group> to identify which table group to clear. Note C<group> only applies when C<--scope=project>. If C<--scope=global> then this option is meaningless and will be ignored. Valid groups are C<cache>, C<plan> and C<project>. C<project> will clear both cache and plan groups (ie, all project related tables.)

=over

=item *

C<cache> - clear only the project tables taskpipe uses for caching

=item *

C<plan> - clear the tables specific to your project without affecting the cache

=item *

C<project> - clear all project tables (both cache and plan)

=back

=cut

has group => (is => 'rw', isa => 'TableGroup', default => 'cache');


=item tables

A comma delimited list of table names to clear. The list should be a subset of the tables in C<--group>. If --tables is omitted, all tables that match C<--group> will be cleared

=cut

has tables => (is => 'rw', isa => 'StrArrayRef');

=item scope

Specify C<project> to clear cache and/or plan tables (use in conjunction with C<group>) - or C<global> to clear global tables (use with caution)

=cut

has scope => (is => 'rw', isa => 'ScopeMode', default => 'project');

=back

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

__PACKAGE__->meta->make_immutable;   
1;



