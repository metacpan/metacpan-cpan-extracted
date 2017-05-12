package Project::Easy::DB;

use Class::Easy;

use DBI;

sub new {
	my $class   = shift;
	my $project = shift;
	my $db_code = shift || 'default';
	
	my $db_conf = $project->config->{db}->{$db_code};
	
	die "db configuration: driver_name must be defined"
		unless defined $db_conf->{driver_name};

	my @connector = ('dbi', $db_conf->{driver_name});
	
	if (exists $db_conf->{attributes}) {
		my %attrs = %{$db_conf->{attributes}};
		push @connector, join ';', map {"$_=$attrs{$_}"} keys %attrs;
	} elsif (exists $db_conf->{dsn_suffix}) {
		die "db configuration: please use 'attributes' hash for setting dsn suffix string";
	}

	my $dsn = join ':', @connector;
	
	die "db configuration: key name 'opts' must be changed to 'options'"
		if exists $db_conf->{opts};
	
	# connect to db
	my $dbh = DBI->connect (
		$dsn,
		$db_conf->{user},
		$db_conf->{pass},
		$db_conf->{options},
	);
	
	if ($dbh and defined $db_conf->{do_after_connect}) {
		my $sql_list = $db_conf->{do_after_connect};
		if (! ref $sql_list) {
			$sql_list = [$sql_list];
		}

		foreach my $sql (@$sql_list) {
			$dbh->do ($sql) or die "can't do $sql";
		}
	}

	# $dbh->trace (1, join ('/', $auction->root, 'var', 'log', 'dbi_trace'));
	
	return $dbh;
}

sub entity {
	my $self = shift;
	my $name = shift;
	
	my ($entity_name, $ds_path, $ds_entity_name, $ds_config_name) = @_;
	
	my $ds_package = $::project->entity_prefix . $ds_entity_name . 'Record';
	my $ds_entity_package = $::project->entity_prefix . $entity_name;
	
	my $use_result = try_to_use_quiet ($ds_entity_package);
	if ($use_result) {
		debug "entity $ds_entity_package $use_result";
		return $ds_entity_package
	}
	
	die "package $ds_entity_package compilation failed with error: $@"
		unless $!;
	
	my $prefix = substr ($::project->entity_prefix, 0, -2);
	
	debug "virtual entity creation (prefix => $prefix, datasource entity package => $ds_entity_package, datasource path => $ds_path, datasource package => $ds_package)";
	
	DBI::Easy::Helper->r (
		$entity_name,
		prefix     => $prefix,
		entity     => $ds_package,
		table_name => $ds_path,
	);
}

sub collection {
	my $self = shift;
	my $name = shift;
	
	my ($entity_name, $ds_path, $ds_entity_name, $ds_config_name) = @_;

	# we must initialize entity prior to collection
	my $entity_package = $self->entity ($name, $entity_name, $ds_path, $ds_entity_name, $ds_config_name);
	
	my $ds_package = $::project->entity_prefix . $ds_entity_name . 'Collection';
	my $ds_collection_package = $::project->entity_prefix . $entity_name. '::Collection';
	
	my $use_result = try_to_use_quiet ($ds_collection_package);
	if ($use_result) {
		debug "collection $ds_collection_package $use_result";
		return $ds_collection_package;
	}

	die "package $ds_collection_package compilation failed with error: $@"
		unless $!;
	
	my $prefix = substr ($::project->entity_prefix, 0, -2);
	
	$ds_path = $entity_package->table_name
		if $entity_package->can ('table_name');
	
	debug "virtual collection creation (prefix => $prefix, datasource collection package => $ds_collection_package, datasource path => $ds_path, datasource package => $ds_package)";
	
	my @params = (
		$entity_name,
		prefix     => $prefix,
		entity     => $ds_package,
		table_name => $ds_path,
	);
	
	push @params, (column_prefix => $entity_package->column_prefix)
		if $entity_package->can ('column_prefix');
	
	DBI::Easy::Helper->c (@params);
}


1;
