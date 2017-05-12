package Project::Easy;

use Class::Easy::Base;
use IO::Easy;

unless ($^O eq 'MSWin32') {
	try_to_use 'Sys::SigAction';
}

# these constants must be available prior to the helper use
BEGIN {
	our $VERSION = '0.30';

	has etc => 'etc'; # conf, config
	has bin => 'bin'; # scripts, tools
	has t   => 't';   # test, tests
};

use Project::Easy::Helper;
use Project::Easy::Config::File;

# because singleton
our $singleton = {};

sub singleton {
	return $singleton;
}

has daemons => {};

has daemon_package => 'Project::Easy::Daemon';
has db_package     => 'Project::Easy::DB';
has conf_package   => 'Project::Easy::Config';

sub import {
	my $pack = shift;
	my @params = @_;
	
	my $caller = caller;
	
	if (scalar grep {$_ eq 'script'} @params or $caller eq 'main') {
		Project::Easy::Helper::_script_wrapper;

		Class::Easy->import;
		IO::Easy->import (qw(project));
	
	} elsif (scalar grep {$_ eq 'project'} @params) {
		Project::Easy::Helper::_script_wrapper (undef, 1);
	
	}
}

sub init {
	my $class = shift;
	
	my $conf_package = $class->conf_package;
	try_to_use ($conf_package)
		or die ('configuration package must exists');
	
	$class->attach_paths;
	
	my $root = dir ($class->lib_path)->parent;

	make_accessor ($class, root => $root);
	
	my $conf_path = $root->append ($class->etc, $class->id . '.' . $class->conf_format)->as_file;
	
	die "can't locate generic config file at '$conf_path'"
		unless -f $conf_path;

	# blessing for functionality extension: serializer
	$conf_path = bless ($conf_path, 'Project::Easy::Config::File');

	make_accessor ($class, conf_path => $conf_path);
	
}

sub instantiate {
	my $class = shift;
	
	die "you cannot use Project::Easy in one project more than one time ($singleton->{_instantiated})"
		if $singleton->{_instantiated};
	
	debug "here we try to detect package location, "
		. "because this package isn't for public distribution "
		. "and must live in <project directory>/lib";
		
	$class->detect_environment;

	my $db_package = $class->db_package;
	try_to_use ($db_package);
	
	bless $singleton, $class;
	
	$singleton->{_instantiated} = $class;

	my $config = $singleton->config;

	foreach my $datasource (keys %{$config->{db}}) {
		my $datasource_package = $config->{db}->{$datasource}->{package};
		
		if (defined $datasource_package) {
			try_to_use ($datasource_package);
		}
		
		# now we must sure to entities packages available
		# and create new ones, if unavailable

		if (defined $datasource_package and $datasource_package->can ('create_entity')) {
			$datasource_package->can ('create_entity')->($class, $class->root, $datasource);
		} else {
			Project::Easy::Helper->can ('create_entity')->($class, $class->root, $datasource);
		}
		

		make_accessor ($class, "db_$datasource" => sub {
			return $class->db ($datasource);
		});
	}
	
	if (exists $config->{daemons}) {
		
		my $d_pack = $class->daemon_package;
		try_to_use ($d_pack);
	
		foreach my $d_name (keys %{$config->{daemons}}) {
			my $d_conf = $config->{daemons}->{$d_name};
			
			my $d;
			
			if ($d_conf->{package}) {
				try_to_use ($d_conf->{package});
				$d = $d_conf->{package}->new ($singleton, $d_name, $d_conf);
			} else {
				$d = $d_pack->new ($singleton, $d_name, $d_conf);
			}
			
			$d->create_script_file ($class->root);
			
			$singleton->daemons->{$d_name} = $d;
		}
	}
	
	return $singleton;
}

sub detect_environment {
	my $class = shift;
	
	my $root = $class->root;
	
	my $distro_path   = $root->append ('var', 'distribution');
	my $instance_path = $root->append ('var', 'instance');
	
	if (-f $distro_path and ! -f $instance_path) {
		rename $distro_path, $instance_path
	}
	
	my @fixups = ();
	$root->dir_io ($class->etc)->scan_tree (sub {
		my $f = shift;
		push @fixups, $f->name
			if -d $f;
	});
	
	my $ending = ".\nprobably you want to set '" 
		. $instance_path->rel_path (dir->current) . '\' contents to fixup config dir name (available fixups: '
		. join (', ', @fixups).")\n";
	
	die "instance file not found" . $ending
		unless -f $instance_path;
	
	my $instance_string = $instance_path->as_file->contents;
	
	$instance_string =~ s/[\s\n\t\r]+$//;

	die "can't recognise instance name '$instance_string'" . $ending
		unless $instance_string;
	
	my ($instance, $fixup_core) = split (/:/, $instance_string, 2); # windows workaround
	
	make_accessor ($class, 'instance', default => $instance);
	make_accessor ($class, 'fixup_core', default => $fixup_core);
	
	my $fixup_path = $class->fixup_path_instance;

	die "can't locate fixup config file at '$fixup_path'" . $ending
		unless -f $fixup_path;
	
	make_accessor ($class, 'fixup_path', default => $fixup_path);
	
}

sub fixup_path_instance {
	my $self   = shift;
	my $instance = shift || $self->instance;
	
	my $fixup_core = $self->fixup_core;
	
	my $fixup_path;
	
	if (defined $fixup_core and $fixup_core) {
		$fixup_path = IO::Easy->new ($fixup_core)->append ($instance);
	} else {
		$fixup_path = $self->root->append ($self->etc, $instance);
	}
	
	$fixup_path = $fixup_path->append ($self->id . '.' . $self->conf_format)->as_file;
	
	bless ($fixup_path, 'Project::Easy::Config::File');
}

sub config {
	my $class = shift;
	
	if (@_ > 0) { # get config for another instance, do not cache
		my $config = $class->conf_package->parse (
			$singleton, @_
		);
		
		# reparse config
		if ($_[0] eq $class->instance) {
			$singleton->{config} = $config
		}
		
		return $config
	}
	
	unless ($singleton->{config}) {
		$singleton->{config} = $class->conf_package->parse (
			$singleton
		);
	}
	
	return $singleton->{config};
}

sub _detect_entity {
	my $self = shift;
	my $name = shift;
	
	# here we need to convert supplied name to outstanding format.
	# name must be in datasource representation (oracle_article) instead of entity (OracleArticle)
	
	my $ds = Project::Easy::Helper::table_from_package ($name);
	
	# for example: $name = 'oracle_article'
	# $ds_config_name - datasource name in configuration (oracle)
	# $ds_path        - for table name in RDBMS (article)
	# $entity_name    - entity name in perl package name (OracleArticle)
	# $ds_entity_name - datasource name in perl package name (Oracle)
	my ($ds_config_name, $ds_path, $entity_name, $ds_entity_name);
	
	$ds_config_name = 'default';
	$ds_entity_name = '';
	$ds_path        = $ds;
	$entity_name    = Project::Easy::Helper::package_from_table ($ds);

	# next, we want to check table name against entity datasource prefixes
	foreach my $k (grep {!/^default$/} keys %{$self->config->{db}}) {
		# my $qk = Project::Easy::Helper::package_from_table ($k);
		
		if (index ($ds, $k) == 0) {
			my $separator = substr ($ds, length($k), 1);
			if ($separator eq '_' or $separator eq ':') {
				$ds_config_name = $k;
				$ds_entity_name = Project::Easy::Helper::package_from_table ($k);
				$ds_path        = substr ($ds, length ($k) + 1);
				$entity_name    = Project::Easy::Helper::package_from_table ($ds);
				last;
			}
		}
	}
	
	debug "datasource: $ds, entity name: $entity_name, datasource path: $ds_path, datasource entity name: $ds_entity_name, datasource config key: $ds_config_name";
	
	return ($entity_name, $ds_path, $ds_entity_name, $ds_config_name);
}

sub entity {
	my $self = shift;
	my $name = shift;
	
	# TODO: make cache for entities
	
	# try to detect entity by prefix
	my ($entity_name, $ds_path, $ds_entity_name, $ds_config_name) = $self->_detect_entity ($name);
	
	my $ds_config = $self->config->{db}->{$ds_config_name};
	
	my $ds_package = $ds_config->{package} || $self->db_package;
	
	debug "datasource package: $ds_package";
	
	$ds_package->entity ($name, $entity_name, $ds_path, $ds_entity_name, $ds_config_name);
}

sub collection {
	my $self = shift;
	my $name = shift;
	
	# TODO: make cache for entities
	
	# try to detect entity by prefix
	my ($entity_name, $ds_path, $ds_entity_name, $ds_config_name) = $self->_detect_entity ($name);
	
	my $ds_config = $self->config->{db}->{$ds_config_name};
	
	my $ds_package = $ds_config->{package} || $self->db_package;
	
	debug "datasource package: $ds_package";
	
	$ds_package->collection ($name, $entity_name, $ds_path, $ds_entity_name, $ds_config_name);
}


sub daemon {
	my $core = shift;
	my $code = shift;
	
	return $core->daemons->{$code};
}

sub db { # TODO: rewrite using alert 
	my $class = shift;
	my $type  = shift || 'default';
	
	my $core = $class->singleton; # fetch current process singleton
	
	$core->{db}->{$type} = {ts => {}}
		unless $core->{db}->{$type};
	
	my $current_db = $core->{db}->{$type};

	my $db_package = $core->config->{db}->{$type}->{package} || $core->db_package;

	unless ($current_db->{$$}) {
		
		$DBI::Easy::ERRHANDLER = sub {
			debug '%%%%%%%%%%%%%%%%%%%%%% DBI ERROR: we relaunch connection %%%%%%%%%%%%%%%%%%%%%%%%';
			debug 'ERROR: ', $@;
			
			$class->_connect_db ($current_db, $db_package, $type, 1);
			
			return $class->db ($type);
		};
		
		my $t = timer ("database handle start");

		$class->_connect_db ($current_db, $db_package, $type);

		$t->end;
		
	}
	
	# we reconnect every hour for morning bug by default
	my $force_reconnect = $core->config->{db}->{$type}->{force_reconnect};
	$force_reconnect = 0
		unless defined $force_reconnect;
	$force_reconnect = 3600
		if $force_reconnect != 0 and $force_reconnect < 3600;
	if ($force_reconnect != 0 and (time - $current_db->{ts}->{$$}) > $force_reconnect) {
		debug "forced reconnect";
		$class->_connect_db ($current_db, $db_package, $type, 1);
	}
	
	return $current_db->{$$};
	
}

sub _connect_db {
	my $class = shift;
	my ($current_db, $db_package, $type, $disconnect) = @_;
	
	my $core = $class->singleton;
	
	my $old_dbh = delete $current_db->{$$};

	if (defined $disconnect and $disconnect) {
		# basic windows support
		eval {
			if ($^O ne 'MSWin32') {
				my $h = Sys::SigAction::set_sig_handler('ALRM', sub {
					# failed disconnect is safe solution
					die;
				});
				alarm (2);
			}
			
			$old_dbh->disconnect
				if $old_dbh;
			
			alarm (0)
				if $^O ne 'MSWin32';
		};
	}

	$current_db->{$$} = $db_package->new ($core, $type);
	$current_db->{ts}->{$$} = time;

}



1;

=head1 NAME

Project::Easy - project deployment made easy.

=head1 SYNOPSIS

	package Caramba;

	use Class::Easy;

	use Project::Easy;
	use base qw(Project::Easy);

	has 'id', default => 'caramba';
	has 'conf_format', default => 'json';

	my $class = __PACKAGE__;

	has 'entity_prefix', default => join '::', $class, 'Entity', '';

	$class->init;

=head1 ACCESSORS

=head2 singleton

=over 4

=item singleton

return class instance

=cut 

=head2 configurable options

=over 4

=item id

project id

=item conf_format

default config file format

=item daemon_package

interface for daemon creation

default => 'Project::Easy::Daemon'

=item db_package

interface for db connections creation

default => 'Project::Easy::DB'

=item conf_package

configuration interface

default => 'Project::Easy::Config';

=item default configuration directory

has 'etc', default => 'etc';

=item default binary directory

has 'bin', default => 'bin';

=cut

=head2 autodetect options

=over 4

=item root

IO::Easy object for project root directory

=item instance

string contains current project instance name

=item fixup_core

path (string) to configuration fixup root

=item conf_path

path object to the global configuration file

=item fixup_path

path object to the local configuration file

=cut

=head1 METHODS

=head2 config

return configuration object

=head2 db

database pool

=cut

=head1 ENTITIES

=over 4

=item intro

Project::Easy create default entity classes on initialization.
this entity based on default database connection. you can use
this connection (not recommended) within modules by mantra:

	my $core = <project_namespace>->singleton;
	my $dbh = $core->db;

method db return default $dbh. you can use non-default dbh named 'cache' by calling:

	my $dbh_cache = $core->db ('cache');

or
	my $dbh_cache = $core->db_cache;

if DBI::Easy default API satisfy you, then you can use database entities
by calling

	my $account_record = $core->entity ('Account');
	my $account_collection = $core->collection ('Account');
	
	my $all_accounts = $account_collection->new->list;

in this case, virtual packages created for entity 'account'.

or you can create these packages by hand:

	package <project_namespace>::Entity::Account;
	
	use Class::Easy;
	
	use base qw(<project_namespace>::Entity::Record);
	
	1;

and for collection:

	package <project_namespace>::Entity::Account::Collection;

	use Class::Easy;

	use base qw(<project_namespace>::Entity::Collection);

	1;

in this case

	my $account_record = $core->entity ('Account');
	my $account_collection = $core->collection ('Account');
	
also works for you

=cut 

=item creation another database entity class

TODO: creation by script

=cut 

=item using entities from multiple databases

TODO: read database tables and create entity mappings,
each entity subclass must contain converted database identifier:

	default entity, table account_settings => entity AccountSettings
	'cache' entity, table account_settings => entity CacheAccountSettings
 

=cut 


=head1 AUTHOR

Ivan Baktsheev, C<< <apla at the-singlers.us> >>

=head1 BUGS

Please report any bugs or feature requests to my email address,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Project-Easy>. 
I will be notified, and then you'll automatically be notified
of progress on your bug as I make changes.

=head1 SUPPORT



=head1 ACKNOWLEDGEMENTS



=head1 COPYRIGHT & LICENSE

Copyright 2007-2009 Ivan Baktsheev

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
