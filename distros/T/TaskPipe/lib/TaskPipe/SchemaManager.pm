package TaskPipe::SchemaManager;

use Moose;
use DBIx::Class::Schema::Loader "make_schema_at";
use DBIx::Error;
use Module::Runtime qw(require_module);
use Moose::Util::TypeConstraints;
use TaskPipe::SchemaManager::Settings;
use TaskPipe::PathSettings;
use TaskPipe::RunInfo;
use File::Spec;
use File::Path 'rmtree';
use Carp;
use Try::Tiny;
use Data::Dumper;
with 'TaskPipe::Role::MooseType_ScopeMode';
with 'MooseX::ConfigCascade';

has scope => (is => 'rw', isa => 'ScopeMode', lazy => 1, default => sub{
    $_[0]->run_info->scope;
});

has run_info => (is => 'ro', isa => 'TaskPipe::RunInfo', default => sub{
    TaskPipe::RunInfo->new;
});

has schema => (is => 'rw', isa => 'DBIx::Class::Schema');
has settings => (is => 'rw', isa => 'TaskPipe::SchemaManager::Settings', lazy => 1, default => sub{
    my $module = __PACKAGE__.'::Settings_'.ucfirst( $_[0]->scope );
    require_module( $module );
    $module->new;
});

has path_settings => (is => 'ro', isa => 'TaskPipe::PathSettings', lazy => 1, default => sub{
    TaskPipe::PathSettings->new( scope => $_[0]->scope );
});

has monikers => (is => 'rw', isa => 'HashRef', lazy => 1, default => sub{
    my $self = shift;

    my @source_names;

    try {
        @source_names = $self->schema->sources;
    } catch {
        confess "Could not determine source names: $_";
    };

    my $m = {};
    foreach my $source_name (@source_names){

        my $source = $self->schema->source( $source_name );
        $m->{ $source->name } = $source_name;

    }

    return $m;
});



sub db_string{
	my $self = shift;

#	my @sp = ();

    use Data::Dumper;
    use MooseX::ConfigCascade::Util;

    my @frags = qw(method type database host port);
    my $db_string = '';
    foreach my $frag ( @frags ){
        if ( $self->settings->$frag ){
            $db_string.=':' if $db_string;
            $db_string.=$self->settings->$frag;
        }

#        confess "A database connect string was requested, but a $frag was not provided. (Check your database connection information in the ".ref( $self->settings )." section of your ".$self->run_info->scope." config. You should have definitions for the following fields: ".join(",",@frags) unless $self->settings->$frag;
#    	push @sp,$self->settings->$frag;

    }

#    my $db_string = join(':',@sp);
	return $db_string;

}


sub connect_schema{
	my ($self,$module) = @_;

    $module ||= $self->settings->module;

    if ( ! $module ){

        confess "I could not find the name of a database schema module to use. Did you forget to enter the correct database settings in the ".ref( $self->settings )." section of your config?";

    }

    try {
    	require_module( $module );
    } catch {
        confess "[B<Require module ($module) failed. (Did you forget to generate the schema? See the help for C<generate schema>:>

    taskpipe help generate schema

B<):>\n$_]";
    };

	my $schema = $module->connect( 
		$self->db_string,
		$self->settings->{username}, 
		$self->settings->{password},
        { HandleError => DBIx::Error->HandleError,
          unsafe => 1,
          ShowErrorStatement => 1 }
	);

    $self->schema( $schema );
    return $schema;
}


sub flush{
    my ($self) = @_;

    $self->schema->storage->disconnect;
    my $schema = $self->connect_schema;
    $self->schema( $schema );

}



sub gen_schema{
    my ($self) = @_;

    $self->clear_schema_path;

	make_schema_at($self->settings->module, { 
        dump_directory => $self->path_settings->path('lib'),
        components => ['InflateColumn::DateTime']
    }, [
		$self->db_string,
		$self->settings->{username},
		$self->settings->{password}
	]);
}


sub clear_schema_path{
    my ($self) = @_;

    my $module = $self->settings->module;
    my $sep = File::Spec->catdir('');
    $module =~ s/::/$sep/g;
    my $schema_path = File::Spec->catdir( 
        $self->path_settings->path('lib'), 
        $module
    );

    rmtree( $schema_path );
}




sub table{
    my ($self, $table_base, $type) = @_;

    my $table_prefix = '';
    if ( ! $type || $type ne 'plan' ){
        $table_prefix = $self->settings->table_prefix || '';
    }

    my $moniker = $self->monikers->{ $table_prefix.$table_base };

    my $rs;

    confess "no moniker. table base: $table_base table_prefix $table_prefix monikers ".Dumper( $self->monikers ) unless $moniker;

    eval{ $rs = $self->schema->resultset( $moniker ); };
    confess $@ if $@;

    return $rs;
}


=head1 NAME

TaskPipe::SchemaManager - manage schema connections for TaskPipe

=head1 DESCRIPTION

It is not recommended to use this module directly. See the general manpages for TaskPipe.

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
