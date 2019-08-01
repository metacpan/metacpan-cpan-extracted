package SqlBatch::Configuration;

# ABSTRACT: Configuration object

use v5.16;
use strict;
use warnings;
use utf8;

use Carp;
use Getopt::Long qw(GetOptionsFromArray);
use DBI;
use JSON::Parse 'json_file_to_perl';
use Data::Dumper;
use SqlBatch::AbstractConfiguration;

sub new {
    my ($class, $config_file_path, %overrides)=@_;

    if (exists $overrides{database_attributes}) {
	croak "Override for 'database_attributes' must be an hash-ref" 
	    unless (ref($overrides{database_attributes}) eq 'HASH');
    }
       
    my $self = SqlBatch::AbstractConfiguration->new(%overrides);

    $self->{config_file_path} = $config_file_path;
    $self->{requirements}     = {
	    datasource          => 1,
	    username            => 1,
	    password            => 1,
	};

    $self = bless $self, $class;

    $self->load if defined $config_file_path;
    $self->validate;

    return $self;    
}

sub load {
    my $self = shift;

    my $path = $self->{config_file_path};

    unless (ref($path)) {
	croak "Configuration file '$path' not found" 
	    unless -e $path;
    }

    $self->{loaded} = json_file_to_perl($path);
}

sub requirement_assertion {
    my $self = shift;
    my $id   = shift;

    for my $item_id (keys %{$self->{requirements}}) {
	if ($self->{requirements}->{$item_id}) {
	    croak "Configuration item '$item_id' is not defined" 
		unless defined $self->item($item_id);
	}
    }    
}

sub validate {
    my $self = shift;
    my %h     = $self->items_hash();
    my @hkeys = keys %h;
    map {$self->requirement_assertion($_) } @hkeys;
}

sub verbosity {
    my $self = shift;
    return $self->item('verbosity') // 0;
}

sub item {
    my $self = shift;
    my $name = shift;

    return $self->{overrides}->{$name} if exists $self->{overrides}->{$name};

    return $self->{loaded}->{$name} if exists $self->{loaded}->{$name};

    return undef;
}

sub items_hash {
    my $self = shift;
    
    return (%{$self->{loaded}},%{$self->{overrides}})
}

sub database_handles {
    my $self = shift;

    my $dbhs = $self->{database_handles};

    unless (defined $dbhs) {
	my $data_source = $self->item('datasource');
	my $username    = $self->item('username');
	my $password    = $self->item('password');
	my $attributes  = $self->item('database_attributes') // {};

	my $dbh_ac = DBI->connect(
	    $data_source, $username, $password, 
	    { %$attributes, RaiseError => 1, AutoCommit => 1 }
	    ) or croak $DBI::errstr;

	my $dbh_nac;
	if ($self->item('force_autocommit')) {
	    # Hack for DBI:RAM and other untransactional databases
	    $dbh_nac=$dbh_ac;
	} else {
	    $dbh_nac= DBI->connect(
		$data_source, $username, $password, 
		{ %$attributes, RaiseError => 1, AutoCommit => 0 }
		) or croak $DBI::errstr;
	}

	$dbhs = {
	    autocommitted    => $dbh_ac,
	    nonautocommitted => $dbh_nac,
	};

	$self->{database_handles} = $dbhs;

	my $init_sql = $self->{init_sql} // [];
	
	for my $statement (@$init_sql) {
	    my $rv = $dbhs->{autocommitted}->do($statement);	    
	}
    }
    
    return $dbhs;
}

sub DESTROY {
    my $self = shift;
}

1;

__END__
    
=head1 NAME

SqlBatch::Configuration

=head1 DESCRIPTION

The given configuration for executing the sqlbatch engine

=head1 ORIGIN OF CONFIGURATION

The values for the configuration items can either come from L<sqlbatch> commandline arguments or from a dedicatet configuration file.

In the situation of doubble definition the commandline arguments prevail.

=head1 METHODS

=over

=item B<database_handles>

Create and return hash with two database connections. The hash contains to elements:

=over

=item C<autocommitted>

Execution on this database handle enables automatic transaction commit.

=item C<nonautocommitted> :

Execution on this database handle will normally not automatically transaction commit.

In the case of a defined item B<force_autocommit> this database handle will also be autocommit enabled.

=back

=item B<load>

Load the given configuration file

=item B<requirement_assertion($name)>

Check if a configuration item requirements are met or croak/die.

=item B<item($name)>

Return value for the given item or return undef.

=item B<item_hash>

Return a hash of item-names and values

=item B<validate>

Execute method C<requirement_assertion> on all items.

=item B<verbosity>

Return the given verbosity level

=back

=head1 CONFIGURATION ITEMS

=over

=item B<datasource> (required)

A DBI connection string

=item B<directory> (optional)

Path to directory for SQL-batch-files and default configuration file.

=item B<exclude_files> (optional, default=[])

Reference to array of filepaths to exclude in execution.

=item B<force_autocommit> (optional, default=undef)

No nonautocommitted database-handle will be created if defined.

=item B<from_file> (optional, default=undef)

Name of the file to start execution from.

=item B<fileextension> (optional, default='sb')

The fileextension of SQL-batch-files.

=item B<password> (required)

Value of the password for doing the DBI connection

=item B<tags> (optional, default=[])

Reference to array of tags that specify running the tagged instructions or not

=item B<to_file> (optional, default=undef)

Name of the file where the execution finishes

=item B<username> (required)

Value of the username for doing the DBI connection

=item B<verbosity> (optional, default=1)

Level of verbosity

    0 : no output
    1 : overall steps
    2 : detailed

=back

=head1 AUTHOR

Sascha Dibbern (sascha at dibbern.info)

=head1 LICENCE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
